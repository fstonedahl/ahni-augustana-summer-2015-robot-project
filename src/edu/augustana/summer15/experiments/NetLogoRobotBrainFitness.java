package edu.augustana.summer15.experiments;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;

import org.apache.commons.math3.linear.ArrayRealVector;
import org.apache.commons.math3.linear.RealVector;
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
public class NetLogoRobotBrainFitness extends BulkFitnessFunctionMT  {

	/**
	 * Parameter for how many trials to run the simulation and take the average result over.
	 * Default: 1
	 */
	public static final String TRIAL_COUNT = "fitness.function.netlogobrain.trial.count";
//	public static final String PERFORMANCE_TRIAL_COUNT = "fitness.function.netlogobrain.performance.trial.count";
	/**
	 * Should every other (even/odd) trial be run right-to-left vs left-to-right?
	 * Note that the total trial count should be EVEN for this to divide evenly. 
	 */
	public static final String TRIAL_AMBIDEXTROUS = "fitness.function.netlogobrain.trial.ambidextrous";

	public static final String MODEL_FILE = "fitness.function.netlogobrain.model.file";
	public static final String MODEL_PARAMETER_OVERRIDES = "fitness.function.netlogobrain.model.parameter.overrides";
	public static final String MODEL_FITNESS_REPORTER = "fitness.function.netlogobrain.model.fitness.reporter";

	
	// Each NetLogo workspace can be used to run the simulation (in parallel)
	private List<HeadlessWorkspace> workspaces = new ArrayList<HeadlessWorkspace>();

	private int trialCount;
	private boolean trialAmbidextrous;
	private int performanceTrialCount;
	private String modelFile;
	private String fitnessReporter;
	
	/**
	 * Construct fitness evaluator with default task arguments/variables.
	 */
	public NetLogoRobotBrainFitness() {
	}
	
	@Override
	public void init(com.ojcoleman.ahni.hyperneat.Properties props) {
		super.init(props);
		trialCount = props.getIntProperty(TRIAL_COUNT, 1);
		performanceTrialCount = trialCount;
		trialAmbidextrous = props.getBooleanProperty(TRIAL_AMBIDEXTROUS, false);
		modelFile = props.getProperty(MODEL_FILE);
		fitnessReporter = props.getProperty(MODEL_FITNESS_REPORTER, "evaluate-fitness");

		String justModelFileName = modelFile.substring(modelFile.lastIndexOf('/') + 1);
		String modelFileBackupLocation = props.getProperty("output.dir") + justModelFileName;
		try {
			Files.copy(new File(modelFile).toPath(), new File(modelFileBackupLocation).toPath());
			logger.info("!! Successfully copied " + modelFile + " to " + modelFileBackupLocation);
		} catch (IOException e1) {
			logger.error("!! ERROR while copying " + modelFile + " to " + modelFileBackupLocation);
			e1.printStackTrace();
		}

		String modelParamOverrides = props.getProperty(MODEL_PARAMETER_OVERRIDES, "");
		String[] overrideList = modelParamOverrides.split(";");

		for (int i = 0; i < this.numThreads; i++) {
			HeadlessWorkspace workspace = HeadlessWorkspace.newInstance();
			workspaces.add(workspace);
			try {
				workspace.open(modelFile);
				for (String override : overrideList) {
					workspace.command(override);
				}
				
				if (i == 0) {
					int numVars = workspace.world().observer().getVariableCount();
				    for (int j = 0; j < numVars; j++)
				    {
			    		String name = workspace.world.observerOwnsNameAt(j);	
			    		// List all the interface parameter except the XML string...
			    		if (!name.equals("XML") && workspace.world().observer().variableConstraint(j) != null) {
			    			Object value = workspace.world().observer().getVariable(j);
			    			logger.info("In NetLogo model: " + name + "=" + value);
			    		}
				    }
				}

			} catch (IOException | CompilerException | LogoException e) {
				e.printStackTrace();
			}
		}		
	};

	
	@Override
	protected void evaluate(Chromosome genotype, Activator substrate, int evalThreadIndex, double[] fitnessValues, Behaviour[] behaviours) {
		_evaluate(genotype, substrate, null, false, false, fitnessValues, behaviours, evalThreadIndex);
	}
	
	@Override
	public void evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage) {
		// avoid doing any extra evaluations just for logging/recording purposes
		// _evaluate(genotype, substrate, baseFileName, logText, logImage, null, null);
		
		// TODO: Maybe try this for more visualization/logging?
		super.evaluate(genotype, substrate, baseFileName, logText, logImage);
	}

	public void _evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage, double[] fitnessValues, Behaviour[] behaviours, int evalThreadIndex) {
		String xml = genotype.getMaterial().toXML();
		HeadlessWorkspace workspace = workspaces.get(evalThreadIndex);
		try {
			workspace.world().setObserverVariableByName("xml", xml);
			//workspace.command("setup");
			double fitnessSum = 0.0;
			for (int i = 0; i < trialCount; i++) {
				if (trialAmbidextrous) {
					workspace.command("set flip-horiz? " + (i%2 == 1));
				}
				double fitness = (double) workspace.report(fitnessReporter);
				fitnessSum += fitness;
			}
			double fitnessAvg = fitnessSum / trialCount;

			double performanceSum = 0.0;
			for (int i = 0; i < performanceTrialCount; i++) {
				if (trialAmbidextrous) {
					workspace.command("set flip-horiz? " + (i%2 == 1));
				}
				double performance = (double) workspace.report(fitnessReporter);
				performanceSum += performance;
			}
			double performanceAvg = performanceSum / performanceTrialCount;

			if (fitnessValues != null) {
				fitnessValues[0] = fitnessAvg;
				genotype.setPerformanceValue(performanceAvg);
			}
			
		} catch (CompilerException | LogoException | AgentException e) {
			e.printStackTrace();
		}
				
	}

	@Override
	public int[] getLayerDimensions(int layer, int totalLayerCount) {
		if (layer == 0) // Input layer.
			return new int[] { 12, 1 };
		else if (layer == totalLayerCount - 1) // Output layer.
			return new int[] { 1, 1 };
		return null;
	}
}
