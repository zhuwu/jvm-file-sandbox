package java.io;

import java.lang.reflect.Field;

public privileged aspect FileInputStreamAspect {
  public FileInputStream.new(boolean internal, File file) throws FileNotFoundException {
    if (internal) {
      System.out.println("Internal file input stream");
      String name = (file != null ? file.getPath() : null);
      if (name == null) {
        throw new NullPointerException();
      }
      if (file.isInvalid()) {
        throw new FileNotFoundException("Invalid file path");
      }

      try {
        final Field closeLockField = FileInputStream.class.getDeclaredField("closeLock");
        Field.setAccessible0(closeLockField, true);
        closeLockField.set(this, new Object());

        final Field fdField = FileInputStream.class.getDeclaredField("fd");
        Field.setAccessible0(fdField, true);
        fdField.set(this, new FileDescriptor());
        // this.fd = new FileDescriptor();
        this.fd.attach(this);

        final Field pathField = FileInputStream.class.getDeclaredField("path");
        Field.setAccessible0(pathField, true);
        pathField.set(this, name);
        // this.path = name;
        this.open0(name);
      } catch (NoSuchFieldException | IllegalAccessException e) {
        e.printStackTrace();
        throw new RuntimeException("Check reflection implementation...");
      }
    } else {
      throw new IllegalArgumentException("The constructor is for internal usage only!");
    }
  }


  private pointcut fileInputStreamOpen(String name): execution(private void FileInputStream.open(String)) && args(name);
  void around(String name) throws FileNotFoundException: fileInputStreamOpen(name) {
    File file = new File(name);

    try {
      System.out.println("Opening a FileInputStream to write, " + file.getCanonicalPath());
    } catch (IOException e) {
      // Ignore
    }

    try {
      String mappedPath = SandboxMapping.sandboxFileRead(file);
      proceed(mappedPath);
    } catch (IOException e) {
      throw new FileNotFoundException();
    }
  }
}
