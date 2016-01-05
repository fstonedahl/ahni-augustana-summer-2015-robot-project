/** An extension to interface with the AHNI library for neuro-evolution,
 *  so we can use the neural networks that get evolved in a NetLogo model...
 */

package org.nlogo.extensions.ahninn;

import java.io.IOException;

import org.jgapcustomised.Chromosome;
import org.jgapcustomised.ChromosomeMaterial;
import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultClassManager;
import org.nlogo.api.DefaultCommand;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.Dump;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.LogoList;
import org.nlogo.api.LogoListBuilder;
import org.nlogo.api.PrimitiveManager;
import org.nlogo.api.Syntax;

import com.anji.integration.Activator;
import com.anji.integration.AnjiActivator;
import com.anji.integration.AnjiNetTranscriber;
import com.anji.integration.TranscriberException;
import com.anji.util.Properties;

public class AHNINNExtension extends DefaultClassManager {
	
	// essentially we want a WeakHashSet but Java has no such class so we use a map but we don't
	  // care what the values are so we use nulls - ST 6/30/09
	  private static final java.util.WeakHashMap<LogoNeuralNetwork, Object> arrays =
	      new java.util.WeakHashMap<LogoNeuralNetwork, Object>();

	  // NOTE/WARNING: I am not worrying about making this LogoObject properly load/save under import/export world, etc.
	  private static class LogoNeuralNetwork
	      // new NetLogo data types defined by extensions must implement
	      // this interface
	      implements org.nlogo.api.ExtensionObject {
		public Activator activator;
		
	    LogoNeuralNetwork(Activator activator) {
	    	this.activator = activator;
		      arrays.put(this, null);
	    }


	    // if we're going to use LogoArrays as keys in a WeakHashMap, we need to make
	    // sure they obey reference equality, otherwise if we have large numbers of
	    // identical arrays the WeakHashMap lookups will take linear time - ST 6/30/09
	    private final Object hashKey = new Object();

	    @Override
	    public int hashCode() {
	      return hashKey.hashCode();
	    }

	    @Override
	    public boolean equals(Object obj) {
	    	if (obj instanceof LogoNeuralNetwork) {
	  	      return this.activator.equals(((LogoNeuralNetwork)obj).activator);	    		
	    	}
    		return false;
	    }

	    public String dump(boolean readable, boolean exporting, boolean reference) {
	    	return "";
		}

	    public String getExtensionName() {
	      return "ahninn";
	    }

	    public String getNLTypeName() {
	      // since this extension only defines one type, we don't
	      // need to give it a name
	      return "";
	    }

		@Override
		public boolean recursivelyEqual(Object arg0) {
			return this.equals(arg0);
		}

	  }

	
    @Override
	public void load( PrimitiveManager primitiveManager )
	{
		primitiveManager.addPrimitive( "create-from-xml" , new CreateFromXML() ) ;
		primitiveManager.addPrimitive( "next" , new Next() ) ;
	}
		
    public static class CreateFromXML extends DefaultReporter
	{
	 public Syntax getSyntax() {
	      return Syntax.reporterSyntax
	          (new int[]{Syntax.StringType()},
	              Syntax.WildcardType());
	    }

	    public String getAgentClassString() {
	      return "OTPL";
	    }

		public Object report( Argument args[] , Context context )
			throws ExtensionException, LogoException 
		{
			String xml = args[ 0 ].getString();
			String PREAMBLE = "String representation of Chromosome:";
			int containsPreamble = xml.indexOf(PREAMBLE);
			if (containsPreamble > -1) {
				xml = xml.substring(containsPreamble + PREAMBLE.length() + 1);
			}
			ChromosomeMaterial cMaterial = ChromosomeMaterial.fromXML(xml);
			Chromosome chromo = new Chromosome(cMaterial, -1L, 0, 0);
			
//			Properties props = null;
//			try {
//				props = new Properties("/home/forrest/git/ahni-augustana-summer-2015-robot-project/properties/simple3xor_netlogo.properties");
//			} catch (IOException e1) {
//				// TODO Auto-generated catch block
//				e1.printStackTrace();
//			}
			Properties props = new Properties();
			props.disableLogger();
			props.put(com.anji.nn.RecurrencyPolicy.KEY,com.anji.nn.RecurrencyPolicy.DISALLOWED.toString());
			props.put(AnjiNetTranscriber.RECURRENT_CYCLES_KEY, 1);
			
			AnjiNetTranscriber transcriber = new AnjiNetTranscriber();
			transcriber.init(props);
			//System.out.println(transcriber.re)
			
			try {
				AnjiActivator activator = transcriber.transcribe(chromo);
				return new LogoNeuralNetwork(activator);
			} catch (TranscriberException e) {
				e.printStackTrace();
				throw new ExtensionException(e);
			}
		}					      
    }
    
    public static class Next extends DefaultReporter
	{
	 public Syntax getSyntax() {
	      return Syntax.reporterSyntax
	          (new int[]{Syntax.WildcardType(), Syntax.ListType()},
	              Syntax.ListType());
	    }

	    public String getAgentClassString() {
	      return "OTPL";
	    }

		public Object report( Argument args[] , Context context )
			throws ExtensionException, LogoException 
		{
			Object arg0 = args[0].get();
		      if (!(arg0 instanceof LogoNeuralNetwork)) {
		        throw new ExtensionException
		            ("not an neural network obj: " + Dump.logoObject(arg0));
		      }
		    LogoNeuralNetwork nn = (LogoNeuralNetwork) arg0;
		    LogoList inputs = args[1].getList();
		    if (inputs.size() != nn.activator.getInputCount()) {
		        throw new ExtensionException
	            ("input list size of " + inputs.size() + " is wrong, should be " + nn.activator.getInputCount() + " to match neural net.");		    	
		    }
		    double[] dInputs = new double[inputs.size()];
		    
		    for (int i = 0; i < dInputs.length; i++) {
		    	Object item = inputs.get(i); 
		    	if (item instanceof Double) {
		    		dInputs[i] = ((Double) item);
		    	} else {
			        throw new ExtensionException
		            ("input list must be all #s, problem: " + Dump.logoObject(item));
		    	}
		    }
		    
		    double[] dOutputs = nn.activator.next(dInputs);
		    LogoListBuilder builder = new LogoListBuilder();
		    for (double d: dOutputs) {
		    	builder.add(d);
		    }
		    return builder.toLogoList();
			
		}					      
    }
    
    
    @Override
    public java.util.List<String> additionalJars() {
        return new java.util.ArrayList<String>() {{
            add("ahni.jar");
        }};
    }
}
