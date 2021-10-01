#!/usr/bin/env bash

rm -rf "./policies.js"
curl -O "https://awspolicygen.s3.amazonaws.com/js/policies.js"
npx prettier --write "./policies.js"
