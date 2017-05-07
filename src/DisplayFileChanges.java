import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class DisplayFileChanges {
    private static HashMap<String, String> fileMappings;
    private static List<String> deleteFiles;

    public static void main(String[] args){
        System.out.println("Enter process ID:");
        Scanner sc = new Scanner(System.in);
        int pid = sc.nextInt();

        String sandbox_dir = "/tmp/cs5231-" + pid;
        String mappingFilePath = sandbox_dir + "-FileMapping.ser";
        loadFileMappings(mappingFilePath);

        deleteFiles = new ArrayList<>();
        for (Map.Entry<String, String> entry : fileMappings.entrySet()) {
            String originalFile = entry.getKey();
            String mappedFile = entry.getValue();
            if (mappedFile.equals("")){
                deleteFiles.add(originalFile);
            }
        }

        List<String> sandboxFiles = new ArrayList<String>();
        walk(sandbox_dir, sandboxFiles);

        if(sandboxFiles.size() == 0){
            System.out.println("No file changes, exit.");
            return;
        }

        showChanges(sandbox_dir, sandboxFiles);

        System.out.println("Do you want to apply the changes? (Y/n)");
        String input = sc.next();
        if(input.trim().toLowerCase().startsWith("y")){
            System.out.println("Approved. Applying changes");
            applyChanges(sandbox_dir, sandboxFiles);

            System.out.println("Changes applied.");


        } else {
            System.out.println("Rejected. Exit.");
        }

    }

    private static void walk(String path, List<String> sandboxFiles) {

        File root = new File(path);
        File[] list = root.listFiles();

        if (list == null) return;

        for (File f : list) {
            String absolutePath = f.getAbsolutePath();
            if(absolutePath.contains(".oracle_jre_usage")){
                continue;
            }

            if (f.isDirectory()) {
                walk(absolutePath, sandboxFiles);
            }
            else {
                sandboxFiles.add(absolutePath);
            }
        }
    }

    private static void loadFileMappings(String filePath) {
        try {
            File mappingFile = new File(filePath);
            FileInputStream fis = new FileInputStream(mappingFile);
            ObjectInputStream ois = new ObjectInputStream(fis);
            fileMappings = (HashMap<String, String>) ois.readObject();
            ois.close();
        } catch (IOException|ClassNotFoundException ex){
            System.err.println("Loading File Mapping Failed.");
        }

    }

    private static void showChanges(String prefix, List<String> sandboxFiles) {
        System.out.println("Changed files are: ");
        int file_index = 1;
        for (String path : sandboxFiles){
            String originalPath = path.replaceFirst(prefix, "");
            System.out.println(file_index + " >> " + originalPath);
            file_index += 1;
        }

        for (String path : deleteFiles){
            System.out.println("Deleted >> " + path);
        }

        int nextInput;
        do {
            Scanner sc = new Scanner(System.in);
            System.out.println("Please select which file to view change: 1 - " + (file_index-1) + ", -1 to break, 0 to show all");

            nextInput = sc.nextInt();
            if(nextInput == 0){
                for(String sandboxPath: sandboxFiles){
                    showDiff(prefix, sandboxPath);
                }
            } else if (nextInput < file_index && nextInput > 0) {
                String sandboxPath = sandboxFiles.get(nextInput - 1);
                showDiff(prefix, sandboxPath);
            }
        } while (nextInput > 0);

    }

    private static void showDiff(String prefix, String sandboxPath){
        String originalPath = sandboxPath.replace(prefix, "");
        System.out.println("Change in " + originalPath + ":");
        String command = "diff " + originalPath + " " + sandboxPath;
        System.out.println();
        try {
            Process p = Runtime.getRuntime().exec(command);
            p.waitFor();

            BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null){
                System.out.println(line);
            }

        } catch (IOException|InterruptedException ex){
            System.err.println("Display file change failed for " + originalPath);
        }
        System.out.println();
    }

    private static void applyChanges(String prefix, List<String> sandboxFiles){
        for (String sandboxFilePath : sandboxFiles) {
            String originalFile = sandboxFilePath.replaceFirst(prefix, "");
            overwriteFile(originalFile, sandboxFilePath);
        }

        for (String path : deleteFiles){
            File toDelete = new File(path);
            toDelete.delete();
        }
    }

    private static void overwriteFile(String originalFile, String sandboxFile){
        try {
            String command = "cp -p " + sandboxFile + " " + originalFile;
            System.out.println("command: " + command);
            Process p = Runtime.getRuntime().exec(command);
            p.waitFor();
        } catch (IOException|InterruptedException ex){
            System.err.println("Apply change for " + originalFile + " failed.");
        }

    }

}
