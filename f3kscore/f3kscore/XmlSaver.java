package f3kscore;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import com.thoughtworks.xstream.XStream;

public class XmlSaver {
	
	public static void main(String[] args) {
		if (args.length != 1) {
			System.out.println("program <in>");
			System.exit(1);
		}
		System.out.println("Saver...");
		try {
			System.out.println("Loading: " + args[0]);
			F3KScore f3kscore = new F3KScore(args[0]);

			Field field = f3kscore.getClass().getDeclaredField("competition");
			field.setAccessible(true);
			Competition competition = (Competition) field.get(f3kscore);
			
			save(args[0] + ".xml", competition);
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		System.exit(0);
		
	}
	
	private static void save(String fileName, Competition competition)
	{
		File file = new File(fileName);
		
		try {
			XStream xstream = new XStream();
			FileOutputStream fs = new FileOutputStream(file);
			ObjectOutputStream oos = xstream.createObjectOutputStream(fs);
			oos.writeObject(competition);
			oos.close();
		}
		catch (IOException e) {
			e.printStackTrace();
		}	
		
	}
	
}
