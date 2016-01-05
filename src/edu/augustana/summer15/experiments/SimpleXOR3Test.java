package edu.augustana.summer15.experiments;

import java.util.ArrayList;
import java.util.Collections;

import org.jgapcustomised.Chromosome;

import com.anji.integration.Activator;
import com.ojcoleman.ahni.evaluation.BulkFitnessFunctionMT;
import com.ojcoleman.ahni.evaluation.novelty.Behaviour;

/**
 * Test evolution on a 3-bit XOR/parity function
 */
public class SimpleXOR3Test extends BulkFitnessFunctionMT  {
	/**
	 * Construct evaluator with default task arguments/variables.
	 */
	public SimpleXOR3Test() {
	}

	
	@Override
	protected void evaluate(Chromosome genotype, Activator substrate, int evalThreadIndex, double[] fitnessValues, Behaviour[] behaviours) {
		try {
		_evaluate(genotype, substrate, null, false, false, fitnessValues, behaviours);
		} catch (ArrayIndexOutOfBoundsException ex) {
			System.err.println("ARGH!");
			ex.printStackTrace();
			throw ex;
		}
	}
	
	@Override
	public void evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage) {
		_evaluate(genotype, substrate, baseFileName, logText, logImage, null, null);
	}

	public void _evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage, double[] fitnessValues, Behaviour[] behaviours) {
		//String xml = genotype.getMaterial().toXML();
		ArrayList<double[]> inputs = new ArrayList<double[]>();
		inputs.add(new double[]{0,0,0});
		inputs.add(new double[]{0,0,1});
		inputs.add(new double[]{0,1,0});
		inputs.add(new double[]{1,0,0});
		inputs.add(new double[]{0,1,1});
		inputs.add(new double[]{1,0,1});
		inputs.add(new double[]{1,1,0});
		inputs.add(new double[]{1,1,1});
		final int NUM_TRIALS = 4;
		double fitness = 0;
		for (int i = 0; i < NUM_TRIALS; i++) {
			Collections.shuffle(inputs);
			for (double[] input : inputs) {
				double[] outputs = substrate.next(input);
				double dAns = outputs[0];
				double realAns = (input[0] + input[1] + input[2]) % 2;
				fitness += Math.abs(dAns - realAns);
			}
		}	
		fitness = 1 - fitness / (8 * NUM_TRIALS); // normalize
		
		if (fitnessValues != null) {
			fitnessValues[0] = fitness;
			genotype.setPerformanceValue(fitness);
		}
	}

	@Override
	public int[] getLayerDimensions(int layer, int totalLayerCount) {
		if (layer == 0) // Input layer.
			return new int[] { 3, 1 };
		else if (layer == totalLayerCount - 1) // Output layer.
			return new int[] { 1, 1 };
		return null;
	}
}
