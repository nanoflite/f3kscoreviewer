package f3kscore;

import java.io.File;
import java.io.FileOutputStream;
import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

import com.thoughtworks.xstream.XStream;

public class XmlSaver {
	
	private String fileName = "";
	private Competition competition = null;
	private F3KScore f3kscore;
	
	public static void main(String[] args) {
		if (args.length != 1) {
			System.out.println("program <in>");
			System.exit(1);
		}
		XmlSaver xmlSaver = new XmlSaver(args[0]);
		xmlSaver.run();
	}
	
	public XmlSaver(String fileName) {
		this.fileName = fileName;
	}
	
	public void run() {
		try {			
			f3kscore = new F3KScore(null);

			Method methodLoad = f3kscore.getClass().getDeclaredMethod("loadFromFile", File.class);
			methodLoad.setAccessible(true);
			File file = new File(fileName);
			methodLoad.invoke(f3kscore, file);

			Field field = f3kscore.getClass().getDeclaredField("competition");
			field.setAccessible(true);			
			this.competition = (Competition) field.get(f3kscore);
			
			Method methodCalcResultList = this.competition.getClass().getDeclaredMethod("calcResultList");
			methodCalcResultList.setAccessible(true);
			methodCalcResultList.invoke(this.competition);
			
			save();
	
			System.exit(0);
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}
	
	private void save()
	{
		try {
			File file = new File(this.fileName + ".xml");
			XStream xstream = new XStream();
			FileOutputStream fs = new FileOutputStream(file);
			ObjectOutputStream oos = xstream.createObjectOutputStream(fs);
			oos.writeObject(this.competition);
			oos.close();
		} catch (Exception e) {
			e.printStackTrace();
		}	
		
	}
	
}
