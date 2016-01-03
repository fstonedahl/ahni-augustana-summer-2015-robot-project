package edu.augustana.summer15.experiments;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;

import org.jgapcustomised.Chromosome;
import org.nlogo.api.AgentException;
import org.nlogo.api.CompilerException;
import org.nlogo.api.LogoException;
import org.nlogo.headless.HeadlessWorkspace;

import com.anji.integration.Activator;
import com.ojcoleman.ahni.evaluation.BulkFitnessFunctionMT;
import com.ojcoleman.ahni.evaluation.novelty.Behaviour;

/**
 * Test running NetLogo with controlling API.
 */
public class SimpleXOR3TestNetLogo extends BulkFitnessFunctionMT  {
	private HeadlessWorkspace workspace;

	/**
	 * Construct evaluator with default task arguments/variables.
	 */
	public SimpleXOR3TestNetLogo() {
		workspace = HeadlessWorkspace.newInstance();
		try {
			workspace.open("/home/forrest/git/AHNINN-Extension/TestNeuroEvolution2.nlogo");
		} catch (IOException | CompilerException | LogoException e) {
			e.printStackTrace();
		}
	}

	
	@Override
	protected void evaluate(Chromosome genotype, Activator substrate, int evalThreadIndex, double[] fitnessValues, Behaviour[] behaviours) {
		_evaluate(genotype, substrate, null, false, false, fitnessValues, behaviours);
	}
	
	@Override
	public void evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage) {
		// _evaluate(genotype, substrate, baseFileName, logText, logImage, null, null);
	}

	public void _evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage, double[] fitnessValues, Behaviour[] behaviours) {
		String xml = genotype.getMaterial().toXML();
		
		try {
			workspace.world().setObserverVariableByName("xml", xml);
			workspace.command("setup");
			double fitness = (double) workspace.report("evaluate");
			//double fitness = Math.random();
			if (fitnessValues != null) {
				fitnessValues[0] = fitness;
				genotype.setPerformanceValue(fitness);
			}
			
		} catch (CompilerException | LogoException | AgentException e) {
			e.printStackTrace();
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
