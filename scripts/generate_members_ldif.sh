#!/bin/bash

# Default values
: ${NUM_USERS:=10000}
: ${USER_BASE_DN:=ou=users,dc=opencloud,dc=eu}
: ${USER_PREFIX:=perf-test-user-}
: ${USER_RDN_ATTRIBUTE:=uid}
: ${GROUP_BASE_DN:=ou=groups,dc=opencloud,dc=eu}
: ${GROUP_NAME:=apollos}
: ${GROUP_RDN_ATTRIBUTE:=cn}

# Generate LDIF for adding members to existing group
echo "# Group membership LDIF file"
echo "# Group name: $GROUP_NAME"
echo "# Group RDN attribute: $GROUP_RDN_ATTRIBUTE"
echo "# Group base DN: $GROUP_BASE_DN"
echo "# Number of users: $NUM_USERS"
echo "# User prefix: $USER_PREFIX"
echo "# User RDN attribute: $USER_RDN_ATTRIBUTE"
echo "# User base DN: $USER_BASE_DN"
echo ""
echo "dn: $GROUP_RDN_ATTRIBUTE=$GROUP_NAME,$GROUP_BASE_DN"
echo "changetype: modify"
echo "add: member"
echo ""

# Add members
for i in $(seq 1 $NUM_USERS); do
    uid="${USER_PREFIX}${i}"
    echo "member: $USER_RDN_ATTRIBUTE=$uid,$USER_BASE_DN"
done

echo ""
echo "# End of group membership LDIF file"