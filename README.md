# jvm-file-sandbox

This is a filesystem sandbox for JVM. The following functionalities are implemented using AspectJ:
* Log the events when filesystem related API is called.
* All the write operation are quarantined. A process can access the content written by itself, but cannot access the quarantined content written by the other processes.
* The user can review the file changes introduced by each process, and choose to accept or reject the changes.

The current implementation only covered `java.io` package, but `java.nio` package can be handled in the similar way.

Build AspectJ Weave-In
```
>> ./build-rt.sh
```

Run test
```
>> ./test.sh
```

Display Changes
```
>> ./display_changes.sh
```
