#!/bin/bash
set -uo pipefail

pass=0
fail=0

# Prints PASS/FAIL for one check and tallies the running totals
check(){
    local desc="$1"
    local status="$2"
    if [ "$status" -eq 0 ]; then
        echo "[PASS] $desc"
        pass=$((pass+1))
    else
        echo "[FAIL] $desc"
        fail=$((fail+1))
    fi
}

# 1. Deployment directory: owned by deploy:deploy, mode 750
owner_group=$(stat -c "%U:%G" /opt/kente-retail/app 2>/dev/null)
[ "$owner_group" =  "deploy:deploy" ]
check "Deployment dir owned by deploy:deploy" $?

perms=$(stat -c "%a" /opt/kente-retail/app 2>/dev/null)
[ "$perms" = "750" ]
check "Deployment dir permissions are 750" $?

# 2. deploy user: home /home/deploy, shell /bin/bash
passwd_line=$(awk -F: '$1 == "deploy" {print $6":"$7}'  /etc/passwd)
[ "$passwd_line" = "/home/deploy:/bin/bash" ]
check "deploy user has home /home/deploy and shell /bin/bash" $?

# 3. ops group has deploy as a member
getent group ops | grep -q '\bdeploy\b'
check "deploy is a member of ops group" $?

# 4. hostname matches kente-<role>-<env> convention
hostname | grep -Eq '^kente-[a-z]+-[a-z0-9]+$'
check "hostname matches kente-<role>-<env> convention" $?

# 5. app responds on port 8080 /health
curl -sf http://localhost:8080/health > /dev/null
check "app responds on port 8080 /health" $?

echo ""
echo "Summary: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
exit $?