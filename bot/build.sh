#!/bin/bash

# Clone our custom easyconfigs
git clone --depth 1 --branch main https://gitrepo.service.rug.nl/cit-hpc/habrok/cit-hpc-easybuild.git

# Start build container
./bot/build_container.sh -o /scratch/public/software-tarballs -- eb  --robot --experimental --easystack easystacks/habrok-2023.01-cvmfs.yml
