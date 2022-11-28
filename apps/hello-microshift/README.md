# Hello, MicroShift! Application

This application serves a static web page with the MicroShift logo and the string "Hello, MicroShift!". Deploy it with

    oc apply -k https://github.com/redhat-et/microshift-demos/apps/hello-microshift?ref=main

The service is exposed via the route `hello-microshift.local`. That route needs to be resolvable to the primary IP address of the machine, e.g. by adding an entry to `/etc/hosts` like

    10.0.2.15   hello-microshift.local
