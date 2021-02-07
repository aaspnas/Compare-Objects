# Security Policy

This consists of a set of Powershell functions, that reads input objects and output text. 
It does not execute system calls or connect over the network. It does not use the file system, 
unless you selet to redirect output. As such the author currently see the risks as small.

## What are the risks?

1: Accidental leakage of information from objects:
   If objects contain sensitive information the data can become visible in the output
   For this the aim is to implement a flag to surpress any output of actual values...
2: ...

## Supported Versions

Only latest version is being updated. Clone and install new version as needed

## Reporting a Vulnerability

Feel free to report any possible issues and security vurnerabilities as GitHub issues. 
