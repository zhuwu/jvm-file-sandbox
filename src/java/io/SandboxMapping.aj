package java.io;

import java.util.*;
import java.lang.management.ManagementFactory;

/**
 * Created by zhangys on 15/10/16.
 */
public privileged aspect SandboxMapping {
  private static String currentPid = "";
  private static HashMap<String, String> fileMappings = new HashMap<>();


  private static void setCurrentPid() {
    currentPid = ManagementFactory.getRuntimeMXBean().getName().split("@")[0];
  }

  public static String getMappingRootDir() throws IOException {
    if ("".equals(currentPid)) {
      setCurrentPid();
    }

    return "/tmp/cs5231-" + currentPid;
  }

  public static void dumpFileMappings(){
    try {
      String fileMappingPath = getMappingRootDir() + "-FileMapping.ser";
      File mappingFile = new File(fileMappingPath);
      OutputStream os = new FileOutputStream(true, mappingFile, true);
      ObjectOutput oo = new ObjectOutputStream(os);
      oo.writeObject(fileMappings);
      oo.close();
    } catch (IOException ex) {
      System.err.println("Dumping file mappings failed.");
    }
  }

  public static boolean copyFile(File source, File destination) {
    // Copy file only when source exists and destination does not exists
    if ((File.fs.getBooleanAttributes(source) & FileSystem.BA_EXISTS) != 0 &&
            (File.fs.getBooleanAttributes(destination) & FileSystem.BA_EXISTS) == 0) {
      FileInputStream input;
      FileOutputStream output;
      try {
        input = new FileInputStream(true, source);
        output = new FileOutputStream(true, destination, false);
        byte[] buf = new byte[1024];
        int bytesRead;
        while ((bytesRead = input.readBytes(buf, 0, buf.length)) > 0) {
          output.writeBytes(buf, 0, bytesRead, false);
        }
        try {
          input.close();
          output.close();
        } catch (IOException e) {
          // Ignore the exception here
        }
        return true;
      } catch (IOException e) {
        return false;
      }
    }
    return false;
  }

  private static String getMappedFilePath(File sourceFile) throws IOException {
    String mappingRoot = getMappingRootDir();
    return mappingRoot + "/" + sourceFile.getCanonicalPath();
  }


  private static void prepareExistingFile(String mappedPath) {
    System.out.println("[prepareExistingFile] Mapped path: " + mappedPath);
    File file = new File(mappedPath);
    if ((File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0) {
      return;
    } else {
      prepareExistingFile(file.getParent());
      File.fs.createDirectory(file);
    }

  }

  private static File findParentFile(File file) throws IOException {
    String path = file.getCanonicalPath();
    System.out.println("[findParentFile] file: " + path);
    if(path.length() <= 1){
      return new File(File.separator);
    } else {
      int index = path.lastIndexOf(File.separatorChar);
      return new File(path.substring(0, index));
    }
  }

  private static boolean prepareSandbox(File file) throws IOException {
    if (file.isFile()) {
      file = findParentFile(file);
    }
    System.out.println("[prepareSandbox] file: " + file.getCanonicalPath());
    while (true) {
      System.out.println("[prepareSandbox][loop] file: " + file.getCanonicalPath());
      String mappedPath = fileMappings.get(file.getCanonicalPath());
      System.out.println("Mapped path: " + mappedPath);
      if (mappedPath != null && !mappedPath.equals("")) {
        // Mapped file in hash map, return
        System.out.println("[prepareSandbox] File in hashmap: " + file.getCanonicalPath());
        return true;
      }

      if ((File.fs.getBooleanAttributes(file) & FileSystem.BA_EXISTS) != 0) {
        mappedPath = getMappedFilePath(file);
        prepareExistingFile(mappedPath);
        return true;

      } else {
        file = findParentFile(file);
      }

    }
  }

  /**
   *
   * @param originalFile
   * @return mapped file path
   * @throws IOException when file already exists
   */
  public static String sandboxFileCreate(File originalFile) throws IOException {
    String originalPath = originalFile.getCanonicalPath();
    String mappedPath = fileMappings.get(originalPath);
    if (mappedPath == null || "".equals(mappedPath)) {
      boolean sandboxPrepared = prepareSandbox(originalFile);
      mappedPath = getMappedFilePath(originalFile);
      fileMappings.put(originalPath, mappedPath);
      dumpFileMappings();
      return mappedPath;
    } else {
      System.err.println("Create File: File " + originalPath + " already exists!");
      throw new IOException("File already exists");
    }
  }

  /**
   *
   * @param originalFile
   * @return
   * @throws IOException
   */
  public static String sandboxFileWrite(File originalFile) throws IOException {
    String originalPath = originalFile.getCanonicalPath();
    System.out.println("[sandboxFileWrite] original path: " + originalPath);
    String mappedPath = fileMappings.get(originalPath);
    if (mappedPath == null || "".equals(mappedPath)) {
      // File not mapped yet. Create and copy original file
      mappedPath = getMappedFilePath(originalFile);
      System.out.println("[sandboxFileWrite] start prepare sandbox");
      boolean sandboxPrepared = prepareSandbox(originalFile);
      fileMappings.put(originalPath, mappedPath);
      dumpFileMappings();
    }
    return mappedPath;
  }

  /**
   * boolean indicates whether the delete should succeed.
   */
  public static String sandboxFileDelete(File originalFile) throws IOException {

    String originalPath = originalFile.getCanonicalPath();
    String mappedPath = fileMappings.get(originalPath);


    if ("".equals(mappedPath)) {
      // File has already been deleted
      return null;
    } else if (mappedPath != null) {
      fileMappings.put(originalPath, "");
      dumpFileMappings();
      return mappedPath;
    } else {
      // When original file exists, call file delete should return true
      if ((File.fs.getBooleanAttributes(originalFile) & FileSystem.BA_EXISTS) != 0) {
        fileMappings.put(originalPath, "");
        dumpFileMappings();
        return "";
      } else {
        return null;
      }
    }

  }

  public static String sandboxFileRead(File originalFile) throws IOException {
    String originalPath = originalFile.getCanonicalPath();
    String mappedPath = fileMappings.get(originalPath);

    if (mappedPath == null) {
      return originalPath;
    }

    if ("".equals(mappedPath)) {
      System.err.println("File " + originalPath + " has been deleted!");
      throw new IOException("File has been deleted");
    }

    return mappedPath;
  }

  public static String sandboxFolderList(File originalFile) throws IOException {
    String originalPath = originalFile.getCanonicalPath();
    String mappedPath = fileMappings.get(originalPath);

    if ("".equals(mappedPath)) {
      // Dir deleted
      System.err.println("Folder " + originalPath + " has been deleted!");
      throw new IOException("Folder has been deleted.");
    }
    return mappedPath;

  }


  public static void main(String[] args) throws IOException {
    File tempFile = new File("/tmp/test-sandbox.txt");

    String createPath = SandboxMapping.sandboxFileCreate(tempFile);
    System.out.println("Create path: " + createPath);

    String readPath = SandboxMapping.sandboxFileRead(tempFile);
    System.out.println("Read path: " + readPath);
    System.out.println("Can delete: " + SandboxMapping.sandboxFileDelete(tempFile));
  }

}
