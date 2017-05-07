package java.io;

import java.lang.reflect.Field;

public privileged aspect FileOutputStreamAspect {
  public FileOutputStream.new(boolean internal, File file, boolean append) throws FileNotFoundException {
    if (internal) {
      System.out.println("Internal file output stream");
      String name = (file != null ? file.getPath() : null);
      if (name == null) {
        throw new NullPointerException();
      }
      if (file.isInvalid()) {
        throw new FileNotFoundException("Invalid file path");
      }

      try {
        final Field closeLockField = FileOutputStream.class.getDeclaredField("closeLock");
        Field.setAccessible0(closeLockField, true);
        closeLockField.set(this, new Object());

        final Field fdField = FileOutputStream.class.getDeclaredField("fd");
        Field.setAccessible0(fdField, true);
        fdField.set(this, new FileDescriptor());
        // this.fd = new FileDescriptor();
        this.fd.attach(this);

        final Field appendField = FileOutputStream.class.getDeclaredField("append");
        Field.setAccessible0(appendField, true);
        appendField.setBoolean(this, append);
        // this.append = false;

        final Field pathField = FileOutputStream.class.getDeclaredField("path");
        Field.setAccessible0(pathField, true);
        pathField.set(this, name);
        // this.path = name;

        this.open0(name, false);
      } catch (NoSuchFieldException | IllegalAccessException e) {
        e.printStackTrace();
        throw new RuntimeException("Check reflection implementation...");
      }
    } else {
      throw new IllegalArgumentException("The constructor is for internal usage only!");
    }
  }

  private pointcut fileOutputStreamOpen(String name, boolean append):
          execution(private void FileOutputStream.open(String, boolean)) && args(name, append);
  void around(String name, boolean append) throws FileNotFoundException: fileOutputStreamOpen(name, append) {
    // proceed(name, append);
    File file = new File(name);

    try {
      System.out.println("Opening a FileOutputStream to write, " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileWrite(file);
      if (append && (File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0) {
        // Copy original file into sandbox if the original file exists and the write is an append
        SandboxMapping.copyFile(file, new File(mappedPath));
      }
      proceed(mappedPath, append);
    } catch (IOException e) {
      throw new FileNotFoundException();
    }
  }
}
