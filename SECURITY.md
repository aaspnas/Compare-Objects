# Security Policy

This consists of a set of Powershell functions, that reads input objects and output text. 
It does not execute system calls or connect over the network. It does not use the file system, 
unless you selet to redirect output. As such the author currently see the risks as small.

## What are the risks?

1: Accidental leakage of information from objects:
    If objects contain sensitive information the data can become visible in the output
    For this the aim is to implement a flag to surpress any output of actual values...
2: Memory exhaustion on host running the script:
    If the object sare large the memory occupied by the analysis script can grow large.
    Make sure that the objects hava a realistic size.
3: CPU exhaustion on host when running the script:
    If the objects are large, the CPU consumption will also grow. Make sure that the objects
    have a realistic size.
4: Endless loops exhausting CPU / Memory:
    As the script use recursion, if the objects contain a property pointing back to a parent 
    object (any object somewhere in the object structure above the current node) an endless loop can result. Make sure your objects are not recursive structures. There is limitation in
    place for the most common cases where for example the object path repeats the same property name several times in a row (/.Value.Value.Value.Value) or the depth reaches 30 nodes.

## Supported Versions

Only latest version is being updated. Clone and install new version as needed

## Reporting a Vulnerability

Feel free to report any possible issues and security vurnerabilities as GitHub issues. 
