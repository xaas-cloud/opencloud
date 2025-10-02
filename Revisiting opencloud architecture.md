# Revisiting opencloud architecture

## Basic functionality
At the lowest level, the core functionality of opencloud allows users to upload files into online drives and sync them with multiple devices. At this level no sharing is invoelved, but it already solves a well understood problem.

### Architecture
We have a proxy (should be our api gateway) that authenticates users (adds traces, logs requests etc) and creates an internal JWT for further authentication in the backend services (although we might still have to forward the original auth headers). The backend consists of a directory of drives the user has access to as well as a service that implements the actual strorage access.

#### System Context diagram for OpenCloud
```mermaid
 C4Context
      title System Context diagram for OpenCloud
      Enterprise_Boundary(b0, "OpenCloud Boundary") {
            Person_Ext(customerC, "An external user", "Cann access shared resources")
            Person(enduserA, "End User A", "An end user of OpenCloud.")
            Person(enduserB, "End User B")
            Person(adminA, "Admin A", "An administrator of OpenCloud.")


            System_Boundary(b1, "OpenCloud Boundary") {
                System(opencloud_system, "OpenCloud", "Allows end users to manage and share files in online drives, sync them with multiple devices and collaborate on them.")
                System_Ext(weboffice_system, "Web Office", "A Collabora Online ", $tags="v1.0")
                System_Ext(antivirus_system, "Antivirus scanner", "A antivirus scanner system", $tags="v1.0")
            }

            Boundary(b3, "Existing services", "boundary") {
                System_Ext(idp_system, "Identity Provider", "An already existing Identity provider", $tags="v1.0")
                ContainerDb_Ext(storage_system, "Storage", "Storage system", "Stores drive content.")
            }
      }

      Rel(enduserA, opencloud_system, "Uses")
      Rel(enduserB, opencloud_system, "Uses")
      Rel(customerC, opencloud_system, "Uses")
      Rel(adminA, opencloud_system, "Administrates")
      Rel(opencloud_system, idp_system, "Uses")
      Rel(opencloud_system, weboffice_system, "Uses")
      Rel(opencloud_system, antivirus_system, "Uses")
      Rel(opencloud_system, storage_system, "Uses")

```

#### Container diagram for OpenCloud

```mermaid
C4Container
    title Container diagram for OpenCloud
	  
    Person(user, Enduser, "An end user of OpenCloud that uses multiple clients", $tags="v1.0")

    Container_Boundary(c1, "OpenCloud") {
        Container(web_app, "Web", "Vue", "Provides all the drive management functionality to end users via their web browser")
        Container(desktop_app, "Desktop", "Java, Spring MVC", "Delivers the static content and the Internet banking SPA")
        Container(android_app, "Android App", "Kotlin, Java", "Provides a limited subset of the drive management functionality to end users via their mobile android device")
        Container(ios_app, "iOS App", "swift", "Provides a limited subset of the drive management functionality to end users via their mobile iOS device")
        Container(backend_api, "OpenCloud System", "Manages access to personal and project drives, etc.")
    }

    Container_Boundary(c2, "External") {
        System_Ext(idp_system, "Identity Provider", "An already existing Identity provider", $tags="v1.0")
        System_Ext(weboffice_system, "Web Office", "A Collabora Online ", $tags="v1.0")
        System_Ext(antivirus_system, "Antivirus scanner", "A antivirus scanner system", $tags="v1.0")
        ContainerDb_Ext(storage_system, "Storage", "Storage system", "Stores drive content.")
    }


    Rel(user, web_app, "Uses", "HTTPS")
    Rel(user, desktop_app, "Uses", "HTTPS")
    Rel(user, android_app, "Uses", "HTTPS")
    Rel(user, ios_app, "Uses", "HTTPS")

    Rel(web_app, backend_api, "Uses", "async, JSON/HTTPS")
    Rel(desktop_app, backend_api, "Uses", "async, JSON/HTTPS")
    Rel(android_app, backend_api, "Uses", "async, JSON/HTTPS")
    Rel(ios_app, backend_api, "Uses", "async, JSON/HTTPS")
    Rel_Back(backend_api, storage_system, "Reads from and writes to", "sync")
    Rel_Back(backend_api, antivirus_system, "checks files with", "ICAP")
    Rel_Back(backend_api, weboffice_system, "makes files available to", "WOPI")

    Rel(idp_system, user, "Sends e-mails to")
    Rel(backend_api, idp_system, "AUthenticates users using", "OpenID Connect")

```

#### Component diagram for OpenCloud

```mermaid
C4Component
    title Component diagram for OpenCloud System - API Application

    Container(web_app, "Web", "Vue", "Provides all the drive management functionality to end users via their web browser")
    Container(desktop_app, "Desktop", "Java, Spring MVC", "Delivers the static content and the Internet banking SPA")
    Container(android_app, "Android App", "Kotlin, Java", "Provides a limited subset of the drive management functionality to end users via their mobile android device")
    Container(ios_app, "iOS App", "swift", "Provides a limited subset of the drive management functionality to end users via their mobile iOS device")
    

    Container_Boundary(backend_api, "OpenCloud System") {

        Component(proxy, "Proxy", "Spring Bean", "Provides functionality related to singing in, changing passwords, etc.")
        Component(registry, "Drive Registry", "go", "A registry for drives.")
        Component(drive, "Drive implementation", "go", "A drive service allowing access to a storage system.")

        Container(wopi, "Collaboration service", "go, WOPI", "Provides a WOPI API.")
        Container(search, "Search service", "go", "provides full text search")
        Container(thumbnails, "Thumbnails service", "go", "generates and caches thumbnails")

    }

    Container_Boundary(existing_systems, "Existing Systems") {

        System_Ext(idp_system, "Identity Provider", "An already existing Identity provider", $tags="v1.0")
        System_Ext(weboffice_system, "Web Office", "A Collabora Online ", $tags="v1.0")
        System_Ext(antivirus_system, "Antivirus scanner", "A antivirus scanner system", $tags="v1.0")
        ContainerDb_Ext(storage_system, "Storage", "Storage system", "Stores drive content.")
    }

    Rel(web_app, proxy, "Uses", "async, JSON/HTTPS")
    Rel(desktop_app, proxy, "Uses", "async, JSON/HTTPS")
    Rel(android_app, proxy, "Uses", "async, JSON/HTTPS")
    Rel(ios_app, proxy, "Uses", "async, JSON/HTTPS")
    Rel_Back(storage_system, drive, "Reads from and writes to", "sync")
    Rel_Back(antivirus_system, drive, "checks files with", "ICAP")
    Rel_Back(weboffice_system, drive, "makes files available to", "WOPI")

    Rel(proxy, idp_system, "Authenticates users using", "OpenID Connect")
```

#### Deployment I am aiming for

For security reasons we want to run any service that has to examine user provided content to run in a dedicated container. This happens when processing a file for e.g. thumbnail generation, context extraction by tika for full text search, antivirus scanning and any online office.

- [ ] TODO where is ldap in here? do we need it for our own account management? maybe a SCIM based service?

```mermaid
    C4Deployment
    title Deployment Diagram for in OpenCloud System - Live

    Deployment_Node(mob, "Customer's mobile device", "Apple IOS or Android"){
        Container(mobile, "Mobile App", "Xamarin", "Provides a limited subset of the OpenCloud functionality to end users via their mobile device.")
    }

    Deployment_Node(comp, "Customer's computer", "Microsoft Windows or Apple macOS"){
        Deployment_Node(browser, "Web Browser", "Google Chrome, Mozilla Firefox,<br/> Apple Safari or Microsoft Edge"){
            Container(web-spa, "OpenCloud Web Single Page Application", "Vue", "Provides all of the OpenCloud functionality<br/>  to end users via their web browser.")
            Container(idp-spa, "Identity Provider Single Page Application", "?", "Provides the Identity Provider functionality<br/>  to end users via their web browser.")
            Container(office-spa, "Online Office Single Page Application", "?", "Provides the Collaborative editing<br/>  of office  documents to end users via their web browser.")
        }
        Deployment_Node(desk, "Desktop client"){
            Container(desktop, "Desktop App", "C++", "Provides a limited subset of the OpenCloud functionality to end users via their desktop client.")
        }
    }

    Deployment_Node(k3s, "Deployment", "Some data center"){

        Deployment_Node(oa, "opencloud-api*** x2"){
            Deployment_Node(opencloud-api, "OpenCloud"){
                Container(proxy, "Proxy", "go", "Provides the gateway to opencloud services with a JSON/HTTPS API.")
            }
        }
        Deployment_Node(web_dn, "opencloud-web*** x2"){
            Deployment_Node(opencloud-web, "go"){
                Container(web, "Web Application", "go", "Delivers the static content and the OpenCloud single page application.")
            }
        }

        %% I'd prefer to replace this with a dedicated idp project ... authelia / authentic?
        Deployment_Node(idp_dn, "opencloud-idp*** x2"){
            Deployment_Node(opencloud-idp, "go"){
                Container(idp, "Web Application", "go", "Delivers the static content and the OpenCloud Identity provider.")
            }
        }
        Deployment_Node(or, "opencloud-registry*** x2"){
            Deployment_Node(opencloud-registry, "OpenCloud"){
                Container(registry, "Registry", "go", "Persists the list of drives users have access to")
            }
        }
        Deployment_Node(od, "opencloud-drive*** x4"){
            Deployment_Node(opencloud-drive, "OpenCloud"){
                Container(drive, "Drive", "go", "Persists the list of drives users have access to")
            }
        }

        Deployment_Node(ot, "opencloud-thumbnails*** x2"){
            Deployment_Node(opencloud-thumbnails, "OpenCloud Thumbnails"){
                Container(thumbnails, "Thumbnails", "go", "Generates and caches thumbnails for OpenCloud")
            }
        }
        
    }
    
    Deployment_Node(na, "nats*** x3"){
        Deployment_Node(nats-cluster, "nats-cluster"){
            ContainerDb_Ext(nats, "Nats", "go", "Provides raft baset consesus cache and persistence for OpenCloud")
        }
    }

    Deployment_Node(ti, "tika*** x2"){
        Deployment_Node(tika-helm, "apache-tika", "apache/tika-helm v3.0.0-full"){
            ContainerDb_Ext(tika, "Tika", "Apache Tika", "Used to extract content for OpenCloud search service")
        }
    }

    Deployment_Node(cav, "clamav*** x2"){
        Deployment_Node(clamav-helm, "wiremind-clamav", "wiremind/clamav?"){
            ContainerDb_Ext(clamav, "ClamAV", "ClamAV", "Used to scan content for viruses")
        }
    }

    Deployment_Node(collab, "collabora-online*** x3"){
        Deployment_Node(collab-helm, "collabora-online", "official collabora-online helm charts"){
            ContainerDb_Ext(collabora-online, "Collabora Online", "C++, JavaScript, TypeScript", "Provides an Online Office for OpenCloud")
        }
    }

    Deployment_Node(sn, "storage") {
        Deployment_Node(stor, "Storage") {
            ContainerDb_Ext(storage, "Storage System", "NFS, GPFS, CephFS, S3", "Persists files")
        }
    }

    Rel(mobile, proxy, "Makes API calls to", "json/HTTPS")
    Rel(web-spa, proxy, "Makes API calls to", "json/HTTPS")
    Rel(office-spa, proxy, "Makes API calls to", "WOPI/HTTPS")
    Rel_U(web, web-spa, "Delivers to the end user's web browser")
    Rel_U(idp, idp-spa, "Delivers to the end user's web browser")
    Rel_U(collabora-online, office-spa, "Delivers to the end user's web browser")
    
    Rel(proxy, registry, "Makes API calls to", "json/HTTPS")
    Rel(proxy, drive, "Makes API calls to", "json/HTTPS")
    Rel(proxy, thumbnails, "Makes API calls to", "json/HTTPS")

    Rel(drive, storage, "Reads from and writes to", "JDBC")

    UpdateRelStyle(web-spa, proxy, $offsetY="-40")
    UpdateRelStyle(web, web-spa, $offsetY="-40")
    UpdateRelStyle(drive, storage, $offsetX="-40", $offsetY="-20")
```

#### deployment we can currently do without changing code


```mermaid
    C4Deployment
    title Deployment Diagram for in OpenCloud System - Live

    Deployment_Node(mob, "Customer's mobile device", "Apple IOS or Android"){
        Container(mobile, "Mobile App", "Xamarin", "Provides a limited subset of the OpenCloud functionality to end users via their mobile device.")
    }

    Deployment_Node(comp, "Customer's computer", "Microsoft Windows or Apple macOS"){
        Deployment_Node(browser, "Web Browser", "Google Chrome, Mozilla Firefox,<br/> Apple Safari or Microsoft Edge"){
            Container(web-spa, "OpenCloud Web Single Page Application", "Vue", "Provides all of the OpenCloud functionality<br/>  to end users via their web browser.")
            Container(idp-spa, "Identity Provider Single Page Application", "?", "Provides the Identity Provider functionality<br/>  to end users via their web browser.")
            Container(office-spa, "Online Office Single Page Application", "?", "Provides the Collaborative editing<br/>  of office  documents to end users via their web browser.")
        }
        Deployment_Node(desk, "Desktop client"){
            Container(desktop, "Desktop App", "C++", "Provides a limited subset of the OpenCloud functionality to end users via their desktop client.")
        }
    }

    Deployment_Node(k3s, "Deployment", "Some data center"){

        Deployment_Node(oa, "opencloud-api*** x2"){
            Deployment_Node(opencloud-api, "OpenCloud"){
                Container(proxy, "Proxy", "go", "Provides the gateway to opencloud services with a JSON/HTTPS API.")
            }
        }

        Deployment_Node(or, "opencloud-registry*** x2"){
            Deployment_Node(opencloud-registry, "OpenCloud"){
                %% HTTP but serving mostly static constent
                Container(web, "Web Application", "go", "Delivers the static content and the OpenCloud single page application.")
                %% I'd prefer to replace this with a dedicated idp project ... authelia / authentic?
                Container(idp, "Web Application", "go", "Delivers the static content and the OpenCloud Identity provider.")

                %% HTTP services
                Container(frontend, "frontend", "go", "Serves the legacy API endpoints")
                Container(graph, "graph", "go", "Serves the /graph endpoint")
                Container(invitations, "invitations", "go", "Serves the /graph/invitations endpoint, currently unused?")
                Container(ocdav, "ocdav", "go", "Serves the /ocdav endpoint")
                Container(ocm, "ocm", "go", "Serves the /ocm endpoint")
                Container(ocs, "ocs", "go", "Serves the legacy /ocs endpoint")
                Container(sse, "sse", "go", "responsible for sending any server side events")
                Container(webdav, "webdav", "go", "Serves the /webdav endpoint, TODO only needed for what?")
                %% TODO webfinger is only needed for sharded deployments, right?
                Container(webfinger, "webfinger", "go", "Serves the /webfinger endpoint")
                
                %% GRPC services
                Container(app-provider, "cs3 app-provider", "go", "TODO used for what? still necessary? part of collaboration service now?")
                Container(app-registry, "cs3 app-registry", "go", "used to configure the default apps for mimetypes")
                Container(auth-app, "cs3 auth-app", "go, CS3 auth-provider", "used to authenticate apps")
                Container(auth-basic, "cs3 auth-basic", "go, CS3 auth-provider", "used to authenticate users using basic auth for testing")
                Container(auth-bearer, "cs3 auth-bearer", "go, CS3 auth-provider", "used to authenticate users using bearer auth")
                %% TODO we should move the oidc auth to a CS3 auth provider instead of in the proxy? really? the proxy should route the request based on the claims. so how would the proxy decide which backend to route a public link request to in case it was sharded? it would have to query all shards concurrently and then cache the result?
                Container(auth-machine, "cs3 auth-machine", "go, CS3 auth-provider", "used to impersonate users")
                Container(auth-service, "cs3 auth-service", "go, CS3 auth-provider", "used to authenticate services")
                Container(gateway, "cs3 gateway", "go", "Serves the CS3 gateway service")
                Container(groups, "cs3 groups", "go", "provides groups to OpenCloud")
                Container(policies, "cs3 policies", "go", "provides policies to OpenCloud")
                Container(sharing, "cs3 sharing", "go", "provides share management to OpenCloud")
                Container(storage-publiclink, "cs3 storageprovider", "go", "provides public link access to OpenCloud")
                Container(storage-shares, "cs3 storageprovider", "go", "provides share access to OpenCloud")
                %% TODO should this be part of the registry?
                Container(storage-system, "cs3 storageprovider", "go", "provides metadata storage to OpenCloud")
                Container(users, "cs3 users", "go", "provides users to OpenCloud")

                %% GRPC and HTTP services
                Container(collaboration, "collaboration", "go", "TODO")
                Container(settings, "settings", "go", "TODO")

                %% LDAP services
                Container(idm, "idm", "go", "persists accounts for OpenCloud")

                %% servers listening on events
                Container(activitylog, "activitylog", "go", "stores events per resource") 
                %% TODO ref using ICAP
                Container(antivirus, "antivirus", "go", "used to send uploaded files to clamav")
                %% TODO needs a persistence store? S3? or is the log just streamed elsewhere
                Container(audit, "audit", "go", "produces an audit log")  
                %% how are the below services queried?
                Container(clientlog, "clientlog", "go", "stores machine readable events for clients") 
                Container(eventhistory, "eventhistory", "go", "persists all events")
                Container(postprocessing, "postprocessing", "go", "handles the coordination of asynchronous postprocessing steps")
                %% search has a GRPC API
                Container(search, "search", "go", "provides search and indexing to OpenCloud")
                Container(userlog, "userlog", "go", "translates and adjusts messages to be human readable") 



            }
        }
        Deployment_Node(od, "opencloud-drive*** x4"){
            Deployment_Node(opencloud-drive, "OpenCloud"){
                Container(drive, "Drive", "go", "Persists the list of drives users have access to")
                Container(storage-users, "cs3 storageprovider", "go", "provides storage spaces to OpenCloud")
            }
        }

        Deployment_Node(ot, "opencloud-thumbnails*** x2"){
            Deployment_Node(opencloud-thumbnails, "OpenCloud Thumbnails"){
                Container(thumbnails, "Thumbnails", "go", "Generates and caches thumbnails for OpenCloud")
            }
        }
        
    }
    
    Deployment_Node(na, "nats*** x3"){
        Deployment_Node(nats-cluster, "nats-cluster"){
            ContainerDb_Ext(nats, "Nats", "go", "Provides raft baset consesus cache and persistence for OpenCloud")
        }
    }

    Deployment_Node(ti, "tika*** x2"){
        Deployment_Node(tika-helm, "apache-tika", "apache/tika-helm v3.0.0-full"){
            ContainerDb_Ext(tika, "Tika", "Apache Tika", "Used to extract content for OpenCloud search service")
        }
    }

    Deployment_Node(cav, "clamav*** x2"){
        Deployment_Node(clamav-helm, "wiremind-clamav", "wiremind/clamav?"){
            ContainerDb_Ext(clamav, "ClamAV", "ClamAV", "Used to scan content for viruses")
        }
    }

    Deployment_Node(collab, "collabora-online*** x3"){
        Deployment_Node(collab-helm, "collabora-online", "official collabora-online helm charts"){
            ContainerDb_Ext(collabora-online, "Collabora Online", "C++, JavaScript, TypeScript", "Provides an Online Office for OpenCloud")
        }
    }

    Deployment_Node(sn, "storage") {
        Deployment_Node(stor, "Storage") {
            ContainerDb_Ext(storage, "Storage System", "NFS, GPFS, CephFS, S3", "Persists files")
        }
    }

    Rel(mobile, proxy, "Makes API calls to", "json/HTTPS")
    Rel(web-spa, proxy, "Makes API calls to", "json/HTTPS")
    Rel(office-spa, proxy, "Makes API calls to", "WOPI/HTTPS")
    Rel_U(web, web-spa, "Delivers to the end user's web browser")
    Rel_U(idp, idp-spa, "Delivers to the end user's web browser")
    Rel_U(collabora-online, office-spa, "Delivers to the end user's web browser")
    
    Rel(proxy, frontend, "Makes API calls to", "json/HTTPS")
    Rel(proxy, drive, "Makes API calls to", "json/HTTPS")
    Rel(proxy, thumbnails, "Makes API calls to", "json/HTTPS")

    Rel(drive, storage, "Reads from and writes to", "JDBC")

    UpdateRelStyle(web-spa, proxy, $offsetY="-40")
    UpdateRelStyle(web, web-spa, $offsetY="-40")
    UpdateRelStyle(drive, storage, $offsetX="-40", $offsetY="-20")
```




