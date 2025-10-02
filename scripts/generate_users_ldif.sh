#!/bin/bash

# Default values
: ${NUM_USERS:=10000}
: ${USER_BASE_DN:=ou=users,dc=opencloud,dc=eu}
: ${USER_PREFIX:=perf-test-user-}
: ${USER_RDN_ATTRIBUTE:=uid}
: ${PASSWORD:=password}
: ${USE_UID_AS_PASSWORD:=true}

# Default lists with fallback values
DEFAULT_FIRST_NAMES="Alice,Bob,Charlie,David,Emma,Frank,Grace,Henry,Ivy,Jack"
DEFAULT_LAST_NAMES="Smith,Johnson,Williams,Brown,Jones,Garcia,Miller,Davis,Rodriguez,Martinez"
DEFAULT_DOMAINS="example.org,test.com,demo.net,dev.org"
DEFAULT_DESCRIPTIONS="A software engineer with expertise in distributed systems.,Data scientist specializing in machine learning and AI.,DevOps engineer with extensive experience in cloud infrastructure.,Frontend developer passionate about modern web technologies.,Backend developer focused on scalable server architecture.,Security specialist with knowledge in penetration testing.,Product manager with a background in software development.,UX designer creating intuitive user experiences.,Database administrator managing large-scale data systems.,System architect designing robust enterprise solutions."

# Read from environment variables or use defaults
FIRST_NAMES=${FIRST_NAMES:-$DEFAULT_FIRST_NAMES}
LAST_NAMES=${LAST_NAMES:-$DEFAULT_LAST_NAMES}
DOMAINS=${DOMAINS:-$DEFAULT_DOMAINS}
DESCRIPTIONS=${DESCRIPTIONS:-$DEFAULT_DESCRIPTIONS}

# Convert comma-separated strings to arrays
IFS=',' read -ra FIRST_NAME_ARRAY <<< "$FIRST_NAMES"
IFS=',' read -ra LAST_NAME_ARRAY <<< "$LAST_NAMES"
IFS=',' read -ra DOMAIN_ARRAY <<< "$DOMAINS"
IFS=',' read -ra DESCRIPTION_ARRAY <<< "$DESCRIPTIONS"

# Generate LDIF header
echo "# Generated LDIF file with $NUM_USERS users"
echo "# User base DN: $USER_BASE_DN"
echo "# User RDN attribute: $USER_RDN_ATTRIBUTE"
echo "# User prefix: $USER_PREFIX"
echo "# Use UID as password: $USE_UID_AS_PASSWORD"
echo "# Password: ${PASSWORD:0:1}..."
echo "# First names: ${FIRST_NAMES}"
echo "# Last names: ${LAST_NAMES}"
echo "# Domains: ${DOMAINS}"
echo ""

# Generate user entries
for i in $(seq 1 $NUM_USERS); do
    # Create unique uid and username
    uid="${USER_PREFIX}${i}"
    
    # Get random first name from array
    first_name_index=$((RANDOM % ${#FIRST_NAME_ARRAY[@]}))
    first_name="${FIRST_NAME_ARRAY[$first_name_index]}"
    
    # Get random last name from array
    last_name_index=$((RANDOM % ${#LAST_NAME_ARRAY[@]}))
    last_name="${LAST_NAME_ARRAY[$last_name_index]}"
    
    # Get random domain from array
    domain_index=$((RANDOM % ${#DOMAIN_ARRAY[@]}))
    domain="${DOMAIN_ARRAY[$domain_index]}"
    
    # Get random description from array
    description_index=$((RANDOM % ${#DESCRIPTION_ARRAY[@]}))
    description="${DESCRIPTION_ARRAY[$description_index]}"
    
    # Generate display name
    display_name="$first_name $last_name"
    
    # Generate email
    mail="${uid}@${domain}"
    
    # Determine password
    if [ "$USE_UID_AS_PASSWORD" = "true" ]; then
        password_value="$uid"
    else
        password_value="$PASSWORD"
    fi
    
    # Generate DN based on RDN attribute
    if [ "$USER_RDN_ATTRIBUTE" = "cn" ]; then
        # When using cn as RDN, uid should be the same as cn for compatibility
        dn="cn=$uid,$USER_BASE_DN"
        cn_value="$uid"
    else
        # Default to uid as RDN
        dn="uid=$uid,$USER_BASE_DN"
        cn_value="$display_name"
    fi
    
    # Output LDIF entry
    echo "dn: $dn"
    echo "objectClass: inetOrgPerson"
    echo "objectClass: organizationalPerson"
    echo "objectClass: person"
    echo "objectClass: top"
    echo "$USER_RDN_ATTRIBUTE: $uid"
    echo "givenName: $first_name"
    echo "sn: $last_name"
    echo "cn: $cn_value"
    echo "displayName: $display_name"
    echo "description: $description"
    echo "mail: $mail"
    echo "userPassword: $password_value"
    
    # Add empty line between entries
    echo ""
done

echo "# End of LDIF file - Generated $NUM_USERS users"