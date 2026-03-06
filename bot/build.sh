#!/bin/bash

# Clone our custom easyconfigs
git clone --depth 1 --branch main https://gitrepo.service.rug.nl/cit-hpc/habrok/cit-hpc-easybuild.git

# Set PR_DIFF
pr_diff=$(ls [0-9]*.diff | head -n 1)

# Get changed easystacks
changed_easystacks=$(
    grep '^+++' "${pr_diff}" |
    cut -f2 -d' ' |
    sed 's@^[a-z]/@@g' |
    grep 'easystacks/.*yml$' |
    grep -Ev 'known-issues|missing|scripts/gpu_support/'
)

if [ -z "${changed_easystacks}" ]; then
    echo "No missing installations, party time!"
    exit 0
fi

# Define build configurations as an associative array
declare -A build_configs=(
    ["regular"]="-o /scratch/public/software-tarballs -- eb --robot --easystack;cvmfs-bot.yml"
    ["generic"]="-g -o /scratch/public/software-tarballs -- eb --robot --easystack;cvmfs-generic.yml"
    ["nfs"]="-r -o /scratch/userapps/hb-software/software-tarballs -- eb --robot --easystack;nfs-generic"
    ["nfs_generic"]="-g -r -o /scratch/userapps/hb-software/software-tarballs -- eb --robot --easystack;nfs-generic"
)

# Function to run build and check
run_build_and_check() {
    local easystacks="$1"
    local build_args="$2"
    local pattern="$3"
    echo "Building easystack ${easystacks}, with build_args: ${build_args} using pattern ${pattern}.\n"
    if [ -n "${easystacks}" ]; then
        ./bot/build_container.sh ${build_args} ${easystacks}
        $TOPDIR/check_missing_installations.sh ${easystacks} ${pr_diff}
    fi
}

# Extract and run builds for each config
for config in "${!build_configs[@]}"; do
    IFS=';' read -r build_args pattern <<< "${build_configs[$config]}"
    easystacks=$(echo "${changed_easystacks}" | grep "${pattern}" || true)
    run_build_and_check "${easystacks}" "${build_args}" "${pattern}"
done
