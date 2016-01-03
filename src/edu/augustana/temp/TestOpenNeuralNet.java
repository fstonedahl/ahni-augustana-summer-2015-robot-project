package edu.augustana.temp;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Arrays;

import org.apache.commons.io.IOUtils;
import org.jgapcustomised.Chromosome;
import org.jgapcustomised.ChromosomeMaterial;

import com.anji.integration.AnjiActivator;
import com.anji.integration.AnjiNetTranscriber;
import com.anji.integration.TranscriberException;
import com.anji.persistence.FilePersistence;
import com.ojcoleman.ahni.hyperneat.Properties;

public class TestOpenNeuralNet {

	public static void main(String[] args) {
		
		try {
//			String bestOfRun = IOUtils.toString(new FileInputStream("data_output/simple3xor/1437341114807/0/best_performing-final-31988.txt"));
			String bestOfRun = IOUtils.toString(new FileInputStream("data_output/simple3xor_netlogo/1437347659330/0/best_performing-final-29620.txt"));
//			String bestOfRun = "<org.jgapcustomised.ChromosomeMaterial>   <primaryParentId>21812</primaryParentId>   <m__alleles>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1015</innovationId>         <type>INPUT</type>         <activationType>linear</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>-0.07979256645403124</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1016</innovationId>         <type>INPUT</type>         <activationType>linear</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>-0.10550894628526986</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1017</innovationId>         <type>INPUT</type>         <activationType>linear</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>-0.021748268398115295</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1018</innovationId>         <type>OUTPUT</type>         <activationType>sigmoid-steep</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>0.04999944170862594</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1019</innovationId>         <srcNeuronId>1015</srcNeuronId>         <destNeuronId>1018</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-1.4134998818013063</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1020</innovationId>         <srcNeuronId>1016</srcNeuronId>         <destNeuronId>1018</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-5.7403640155403775</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1021</innovationId>         <srcNeuronId>1017</srcNeuronId>         <destNeuronId>1018</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>5.649296998286464</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1022</innovationId>         <type>OUTPUT</type>         <activationType>sigmoid-steep</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>0.31542835885230497</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1023</innovationId>         <srcNeuronId>1015</srcNeuronId>         <destNeuronId>1022</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-5.387683221669866</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1024</innovationId>         <srcNeuronId>1016</srcNeuronId>         <destNeuronId>1022</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-4.387750187202853</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1025</innovationId>         <srcNeuronId>1017</srcNeuronId>         <destNeuronId>1022</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>0.9104852430488071</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.NeuronAllele>       <gene class=\"com.anji.neat.NeuronGene\">         <innovationId>1026</innovationId>         <type>OUTPUT</type>         <activationType>sigmoid-steep</activationType>       </gene>       <neuronGene reference=\"../gene\"/>       <bias>-0.7152568394331715</bias>     </com.anji.neat.NeuronAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1027</innovationId>         <srcNeuronId>1015</srcNeuronId>         <destNeuronId>1026</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-3.5758640124830103</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1028</innovationId>         <srcNeuronId>1016</srcNeuronId>         <destNeuronId>1026</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-0.4572843104470927</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>1029</innovationId>         <srcNeuronId>1017</srcNeuronId>         <destNeuronId>1026</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>1.328299405753064</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>2036</innovationId>         <srcNeuronId>1016</srcNeuronId>         <destNeuronId>1017</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-0.3143413900298908</weight>     </com.anji.neat.ConnectionAllele>     <com.anji.neat.ConnectionAllele>       <gene class=\"com.anji.neat.ConnectionGene\">         <innovationId>2057</innovationId>         <srcNeuronId>1018</srcNeuronId>         <destNeuronId>1018</destNeuronId>       </gene>       <connectionGene reference=\"../gene\"/>       <weight>-1.1116654289968184</weight>     </com.anji.neat.ConnectionAllele>   </m__alleles>   <shouldMutate>true</shouldMutate>   <pruned>true</pruned> </org.jgapcustomised.ChromosomeMaterial>";

			String bestOfRunXML = bestOfRun.substring(bestOfRun.indexOf("<org."));
			ChromosomeMaterial cMaterial = ChromosomeMaterial.fromXML(bestOfRunXML);
			Chromosome chromo = new Chromosome(cMaterial, -1L, 0, 0);
			
			Properties props = new Properties("properties/simple3xor_v2.properties");
			//Properties props = new Properties();
			//props.put(AnjiNetTranscriber.RECURRENT_CYCLES_KEY, 1);
			
			AnjiNetTranscriber transcriber = new AnjiNetTranscriber();
			transcriber.init(props);
			//System.out.println(transcriber.re)
			
			AnjiActivator activator = transcriber.transcribe(chromo);
			double[] input = new double[activator.getInputCount()];
			
			double output[] = activator.next(new double[] {0, 0, 0});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {1, 0, 1});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {0, 1, 1});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {1, 1, 0});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {1, 0, 0});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {0, 1, 0});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {0, 0, 1});
			System.out.println(String.format("%.1f",output[0]));
			output = activator.next(new double[] {1, 1, 1});
			System.out.println(String.format("%.1f",output[0]));
			
		} catch (TranscriberException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}

}
