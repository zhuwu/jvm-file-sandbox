import java.io.*;

public class FileTest {

  private static final String DATA_FOLDER = System.getProperty("project.path") + "/data/";

  public static void main(String[] args) {
    try {
      System.out.println("Start file test..");

      testCreateNewFile();
      testReadFile();
      testUpdateFile();
      testModifyFile();
      testDeleteFile();

      System.out.println("Complete file Test.");

    } catch (IOException ex) {
        ex.printStackTrace();

    }
  }

  private static void testCreateNewFile() throws IOException{
    System.out.println("================= Testing Create File =================");

    File newFile = new File(DATA_FOLDER + "new_created_file.txt");
    newFile.createNewFile();

    PrintWriter writer = new PrintWriter(newFile);

    writer.println("During his election campaign, Mr Trump described Western military alliance Nato as obsolete.");
    writer.println("He suggested that the US would think twice about coming to the aid of any Nato ally under attack if it had not paid its dues.");
    writer.close();
  }

  private static void testReadFile() throws IOException{
    System.out.println("================= Testing Read File =================");
    BufferedReader bf = new BufferedReader(new FileReader(DATA_FOLDER + "test_read.txt"));

    String line;
    while((line = bf.readLine())!= null){
      System.out.println("test_update.txt >>> " + line);
    }
  }

  private static void testUpdateFile() throws IOException {
    System.out.println("================= Testing Update File =================");
    BufferedWriter writer = new BufferedWriter(new FileWriter(DATA_FOLDER + "test_update.txt", true));
    writer.write("Painting: Frederic Remington\n\n");
    writer.write("Recently featured: Inuit woman Netherlands American Cemetery\n");
    writer.close();
  }

  private static void testModifyFile() throws IOException {
    System.out.println("================= Testing Modify File =================");
    File toModifyFile = new File(DATA_FOLDER + "test_modify.txt");
    boolean canWrite = toModifyFile.canWrite();

    System.out.println("Change writable to: "+ !canWrite);
    toModifyFile.setWritable(!canWrite);


  }

  private static void testDeleteFile() throws IOException {
    System.out.println("================= Testing Delete File =================");
    File toDeleteFile = new File(DATA_FOLDER + "test_delete.txt");
    toDeleteFile.delete();
  }

}
