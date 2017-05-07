package java.io;

public privileged aspect FileAspect {
  private pointcut fileCanExecute(): execution(boolean File.canExecution());
  boolean around(): fileCanExecute() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkExec(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.canExecution " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return File.fs.checkAccess(mappedFile, FileSystem.ACCESS_EXECUTE);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.checkAccess(file, FileSystem.ACCESS_EXECUTE);
  }

  private pointcut fileCanRead(): execution(boolean File.canRead());
  boolean around(): fileCanRead() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkRead(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.canRead " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return File.fs.checkAccess(mappedFile, FileSystem.ACCESS_READ);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.checkAccess(file, FileSystem.ACCESS_READ);
  }

  private pointcut fileCanWrite(): execution(boolean File.canWrite());
  boolean around(): fileCanWrite() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.canWrite " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return File.fs.checkAccess(mappedFile, FileSystem.ACCESS_WRITE);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.checkAccess(file, FileSystem.ACCESS_WRITE);
  }

  private pointcut fileCreateNewFile(): execution(boolean File.createNewFile());
  boolean around() throws IOException: fileCreateNewFile() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) security.checkWrite(file.path);
    if (file.isInvalid()) {
      throw new IOException("Invalid file path");
    }

    try {
      System.out.println("Calling File.createNewFile " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    // Follow the default Java behavior. Return false when the file to create already exists.
    if (((File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0)) {
      return false;
    }

    String mappedPath;
    try {
      mappedPath = SandboxMapping.sandboxFileCreate(file);
    } catch (IOException e) {
      // Follow the default Java behavior. Return false when the file to create already exists.
      return false;
    }
    return File.fs.createFileExclusively(mappedPath);
    // return File.fs.createFileExclusively(file.path);
  }

  private pointcut fileCreateTempFile(String prefix, String suffix, File directory):
          execution(File File.createTempFile(java.lang.String, java.lang.String, File)) && args(prefix, suffix, directory);
  File around(String prefix, String suffix, File directory) throws IOException: fileCreateTempFile(prefix, suffix, directory) {
    if (prefix.length() < 3)
      throw new IllegalArgumentException("Prefix string too short");
    if (suffix == null)
      suffix = ".tmp";

    File tmpdir = (directory != null) ? directory
            : File.TempDirectory.location();
    SecurityManager sm = System.getSecurityManager();
    File f;
    do {
      f = File.TempDirectory.generateFile(prefix, suffix, tmpdir);

      if (sm != null) {
        try {
          sm.checkWrite(f.getPath());
        } catch (SecurityException se) {
          // don't reveal temporary directory location
          if (directory == null)
            throw new SecurityException("Unable to create temporary file");
          throw se;
        }
      }
    } while ((File.fs.getBooleanAttributes(f) & FileSystem.BA_EXISTS) != 0);

    System.out.println("Calling File.createTempFile");

    // Just throw exception when file name crashed... because we are lazy!
    String mappedPath = SandboxMapping.sandboxFileCreate(f);
    if (!File.fs.createFileExclusively(mappedPath))
      throw new IOException("Unable to create temporary file");
    return new File(mappedPath);

    // if (!File.fs.createFileExclusively(f.getPath()))
    //  throw new IOException("Unable to create temporary file");
    // return f;
  }

  private pointcut fileDelete(): execution(boolean File.delete());
  boolean around(): fileDelete() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkDelete(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.delete " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileDelete(file);
      return mappedPath != null && (mappedPath.equals("") || File.fs.delete(new File(mappedPath)));
    } catch (IOException e) {
      return false;
    }

    // return File.fs.delete(file);
  }

  private pointcut fileExists(): execution(boolean File.exists());
  boolean around(): fileExists() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkRead(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.exists " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return ((File.fs.getBooleanAttributes(mappedFile) & FileSystem.BA_EXISTS) != 0);
    } catch (IOException e) {
      return false;
    }
    // return ((File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0);
  }

  private pointcut fileLastModified(): execution(long File.lastModified());
  long around(): fileLastModified() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkRead(file.path);
    }
    if (file.isInvalid()) {
      return 0L;
    }

    try {
      System.out.println("Calling File.lastModified " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return File.fs.getLastModifiedTime(mappedFile);
    } catch (IOException e) {
      return 0L;
    }
    // return File.fs.getLastModifiedTime(file);
  }

  private pointcut fileLength(): execution(long File.length());
  long around(): fileLength() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkRead(file.path);
    }
    if (file.isInvalid()) {
      return 0L;
    }

    try {
      System.out.println("Calling File.length " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      File mappedFile = new File(mappedPath);
      return File.fs.getLength(mappedFile);
    } catch (IOException e) {
      return 0L;
    }
    // return File.fs.getLength(file);
  }

  private pointcut fileList(): execution(String[] File.list());
  String[] around(): fileList() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkRead(file.path);
    }
    if (file.isInvalid()) {
      return null;
    }

    try {
      System.out.println("Calling File.list " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    // String[] originalList = File.fs.list(file);


    // File mappedFile = new File(mappedPath);
    // return File.fs.list(mappedFile);
    // How to list a dirty directory?
    return File.fs.list(file);
  }

  private pointcut fileMkdir(): execution(boolean File.mkdir());
  boolean around(): fileMkdir() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.mkdir " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    // Follow the default Java behavior. Return false when the directory to create already exists.
    if (((File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0)) {
      return false;
    }

    String mappedPath;
    try {
      mappedPath = SandboxMapping.sandboxFileCreate(file);
    } catch (IOException e) {
      // Follow the default Java behavior. Return false when the directory to create already exists.
      return false;
    }

    File mappedFile = new File(mappedPath);
    return File.fs.createDirectory(mappedFile);
    // return File.fs.createDirectory(file);
  }

  private pointcut fileRenameTo(File dest): execution(boolean File.renameTo(File)) && args(dest);
  boolean around(File dest): fileRenameTo(dest) {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
      security.checkWrite(dest.path);
    }
    if (dest == null) {
      throw new NullPointerException();
    }
    if (file.isInvalid() || dest.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.fileRenameTo " + file.getCanonicalPath() + ". Parameter: " + dest.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      String mappedDestPath = SandboxMapping.sandboxFileWrite(dest);
      File mappedFile = new File(mappedPath);
      File mappedDestFile = new File(mappedDestPath);
      boolean result = File.fs.rename(mappedFile, mappedDestFile);
      if (result) {
        SandboxMapping.sandboxFileDelete(file);
      }
      return result;
    } catch (IOException e) {
      return false;
    }
    // return File.fs.rename(file, dest);
  }

  private pointcut fileSetExecutable(boolean executable, boolean ownerOnly):
          execution(boolean File.setExecutable(boolean, boolean)) && args(executable, ownerOnly);
  boolean around(boolean executable, boolean ownerOnly): fileSetExecutable(executable, ownerOnly) {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.fileSetExecutable " + file.getCanonicalPath() + ". Parameter: " + executable + ", " + ownerOnly);
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      File mappedFile = new File(mappedPath);
      SandboxMapping.copyFile(file, mappedFile);
      return File.fs.setPermission(mappedFile, FileSystem.ACCESS_EXECUTE, executable, ownerOnly);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.setPermission(file, FileSystem.ACCESS_EXECUTE, executable, ownerOnly);
  }

  private pointcut fileSetLastModified(long time): execution(boolean File.setLastModified(long)) && args(time);
  boolean around(long time): fileSetLastModified(time) {
    File file = (File) thisJoinPoint.getThis();
    if (time < 0) throw new IllegalArgumentException("Negative time");
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.setLastModified " + file.getCanonicalPath() + ". Parameter: " + time);
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      File mappedFile = new File(mappedPath);
      SandboxMapping.copyFile(file, mappedFile);
      return File.fs.setLastModifiedTime(mappedFile, time);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.setLastModifiedTime(file, time);
  }

  private pointcut fileSetReadable(boolean readable, boolean ownerOnly):
          execution(boolean File.setReadable(boolean, boolean)) && args(readable, ownerOnly);
  boolean around(boolean readable, boolean ownerOnly): fileSetReadable(readable, ownerOnly) {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.setReadable " + file.getCanonicalPath() + ". Parameter: " + readable + ", " + ownerOnly);
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      File mappedFile = new File(mappedPath);
      SandboxMapping.copyFile(file, mappedFile);
      return File.fs.setPermission(mappedFile, FileSystem.ACCESS_READ, readable, ownerOnly);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.setPermission(file, FileSystem.ACCESS_READ, readable, ownerOnly);
  }

  private pointcut fileSetReadonly(): execution(boolean File.setReadOnly());
  boolean around(): fileSetReadonly() {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.setReadOnly " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      File mappedFile = new File(mappedPath);
      SandboxMapping.copyFile(file, mappedFile);
      return File.fs.setReadOnly(mappedFile);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.setReadOnly(file);
  }

  private pointcut fileSetWritable(boolean writable, boolean ownerOnly):
          execution(boolean File.setWritable(boolean, boolean)) && args(writable, ownerOnly);
  boolean around(boolean writable, boolean ownerOnly): fileSetWritable(writable, ownerOnly) {
    File file = (File) thisJoinPoint.getThis();
    SecurityManager security = System.getSecurityManager();
    if (security != null) {
      security.checkWrite(file.path);
    }
    if (file.isInvalid()) {
      return false;
    }

    try {
      System.out.println("Calling File.setWritable " + file.getCanonicalPath() + ". Parameter: " + writable + ", " + ownerOnly);
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      File mappedFile = new File(mappedPath);
      SandboxMapping.copyFile(file, mappedFile);
      return File.fs.setPermission(mappedFile, FileSystem.ACCESS_WRITE, writable, ownerOnly);
    } catch (IOException e) {
      return false;
    }
    // return File.fs.setPermission(file, FileSystem.ACCESS_WRITE, writable, ownerOnly);
  }
}
