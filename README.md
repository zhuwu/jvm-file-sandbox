# jvm-file-sandbox

This is a filesystem sandbox for JVM. The following functionalities are implemented:
* Log the events when filesystem related API is called.
* All the write operation are quarantined. A process can access the quarantined content written by itself, but cannot access the quarantined content written by the other processes.
* The user can review the file changes introduced by each process, and choose to accept or reject the changes.

The current implementation only covered `java.io` package, but `java.nio` package can be handled in the similar way. AspectJ is used in the implementation to inject functionalities to Java runtime.

---

Build woven Java runtime:
```
>> ./build-rt.sh
```

Run test
```
>> ./test.sh
```

Display Filesystem Changes
```
>> ./display_changes.sh
```
