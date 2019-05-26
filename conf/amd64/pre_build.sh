#!/bin/bash

sed -i -e 's/BR2_TARGET_GENERIC_GETTY_PORT.*/BR2_TARGET_GENERIC_GETTY_PORT="ttyS0"/' .config
