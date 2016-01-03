package com.ojcoleman.ahni.experiments;

import java.io.FileWriter;
import java.io.IOException;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

import org.apache.commons.math3.linear.ArrayRealVector;
import org.apache.log4j.Logger;
import org.jgapcustomised.Chromosome;

import com.anji.integration.Activator;
import com.ojcoleman.ahni.evaluation.BulkFitnessFunctionMT;
import com.ojcoleman.ahni.evaluation.novelty.Behaviour;
import com.ojcoleman.ahni.evaluation.novelty.RealVectorBehaviour;
import com.ojcoleman.ahni.event.AHNIEvent;
import com.ojcoleman.ahni.event.AHNIEventListener;
import com.ojcoleman.ahni.hyperneat.Properties;
import com.ojcoleman.ahni.nn.BainNN;
import com.ojcoleman.ahni.nn.NNAdaptor;
import com.ojcoleman.ahni.util.ArrayUtil;
import com.ojcoleman.ahni.util.CircularFifoBuffer;
import com.ojcoleman.ahni.util.NiceWriter;
import com.ojcoleman.ahni.util.Range;

public class TSPSuperimposedWaves extends BulkFitnessFunctionMT implements AHNIEventListener {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(BulkFitnessFunctionMT.class);
	private static final NumberFormat nf = new DecimalFormat(" 0.000;-0.000");
	
	/**
	 * The seed to use for the RNG to generate the network. Comment out to use seed based on current time.
	 */
	public static final String SEED = "fitness.function.tspsw.seed";
	/**
	 * The number of waves to superimpose.
	 */
	public static final String WAVE_COUNT_INITIAL = "fitness.function.tspsw.wave.count";
	/**
	 * The amount to increase the number of waves by when environments with the current value have been sufficiently mastered
	 * (see {@link #DIFFICULTY_INCREASE_PERFORMANCE}. If the value is followed by an "x" then the value is considered a
	 * factor (and so should be > 1). If a factor >= 1 is supplied then the wave count will always be increased by at least 1.
	 */
	public static final String WAVE_COUNT_DELTA = "fitness.function.tspsw.wave.count.delta";
	/**
	 * Comma-separated list of available types of waves. These are selected at random when generating environments. 
	 * Valid values are sine, square, triangle and saw. Default is sine only.
	 */
	public static final String WAVE_TYPES = "fitness.function.tspsw.wave.types";
	/**
	 * The evaluation method to use. Either 'reproduce' (the network must continue to produce the signal during 
	 * the evaluation phase) or 'predict' (the network must predict the signal value 
	 * fitness.function.tspsw.evaluation.predict.lookahead steps ahead).  
	 */
	public static final String EVAL_TYPE = "fitness.function.tspsw.evaluation.type";
	/**
	 * When fitness.function.tspsw.evaluation.type = 'predict', the number of time steps ahead that the network must
	 * predict the signal value for.  
	 */
	public static final String EVAL_PREDICT_LOOKAHEAD = "fitness.function.tspsw.evaluation.predict.lookahead";
	/**
	 * The length of the learning phase.
	 */
	public static final String PHASE_LEARN_LENGTH = "fitness.function.tspsw.phase.learn.length";
	/**
	 * The length of the evaluation phase.
	 */
	public static final String PHASE_EVAL_LENGTH = "fitness.function.tspsw.phase.evaluation.length";
	/**
	 * The performance indicating when the environment difficulty should be increased as the current difficulty has been
	 * sufficiently mastered.
	 */
	public static final String DIFFICULTY_INCREASE_PERFORMANCE = "fitness.function.tspsw.difficulty.increase.performance";
	/**
	 * The (initial) number of environments to evaluate candidates against. Increasing this will provide a more 
	 * accurate evaluation but take longer.
	 */
	public static final String ENVIRONMENT_COUNT = "fitness.function.tspsw.environment.count";
	/**
	 * The fraction of environments that should be replaced with new environments per generation. This is evaluated
	 * probabilistically.
	 */
	public static final String ENVIRONMENT_CHANGE_RATE = "fitness.function.tspsw.environment.replacerate";
	/**
	 * Factor to increase the total number of environments by when the current environment(s) have been 
	 * sufficiently mastered (see {@link #DIFFICULTY_INCREASE_PERFORMANCE}. May be fractional; if the factor is 
	 * greater than 1 then the number of environments will be increased by at least 1. Default is 1 (no change).
	 */
	public static final String ENVIRONMENT_INCREASE_RATE = "fitness.function.tspsw.environment.count.increase";
	/**
	 * If {@link #DIFFICULTY_INCREASE_PERFORMANCE} is greater than 1, then this is the maximum number of 
	 * environments to increase to. Default is 128.
	 */
	public static final String ENVIRONMENT_COUNT_MAX = "fitness.function.tspsw.environment.count.max";
	
	/**
	 * If true enables novelty search for which behaviours are defined by the output of the system for the last  
	 * iterations in the final trial. Default is false.
	 */
	public static final String NOVELTY_SEARCH = "fitness.function.tspsw.noveltysearch";
	/**
	 * The number of iterations to record the output for when creating a novelty search behaviour. Default is 8. 
	 */
	public static final String NOVELTY_SEARCH_RECORD_LENGTH = "fitness.function.tspsw.noveltysearch.record_length";
	/**
	 * If set to an integer > 0 then this many environments will be used to characterise an agents behaviour for novelty
	 * search. Defaults to fitness.function.tspsw.env.count.
	 */
	public static final String NOVELTY_SEARCH_ENV_COUNT = "fitness.function.tspsw.noveltysearch.envs.count";
	/**
	 * If true then makes novelty search the only objective. Performance values are still calculated. Default is false. 
	 * If true then fitness.function.tspsw.noveltysearch is forced to true and fitness.function.tspsw.env.replacerate is 
	 * forced to 0, and fitness.function.tspsw.noveltysearch.envs.count is forced to fitness.function.tspsw.environment.count, 
	 * so that the same environments are used for calculating performance and novelty.
	 */
	public static final String NOVELTY_SEARCH_ONLY = "fitness.function.tspsw.noveltysearch.only";
	
	public enum EvalType { REPRODUCE, PREDICT }
	
	private int environmentCount;
	private double environmentReplaceProb;
	private double environmentIncreaseRate;
	private int environmentCountMax;
	private EvalType evalType;
	private int evalPredictLookahead;
	private int phaseLearnLength;
	private int phaseEvalLength;
	private int waveCount;
	private WaveType[] waveTypes;
	private Environment[] environments;
	private Environment[] nsEnvironments;
	private Environment[] genEnvironments;
	private int environmentCounter = 0;
	private Random envRand;
	private boolean noveltySearchEnabled = false;
	private boolean noveltySearchOnly = false;
	private int noveltySearchEnvCount;
	private int totalNSBehaviourSize;
	private int nsRecordLength;
	private int nsStartRecordAtStep;

	@Override
	public void init(Properties props) {
		noveltySearchOnly = props.getBooleanProperty(NOVELTY_SEARCH_ONLY, false);
		noveltySearchEnabled = noveltySearchOnly || props.getBooleanProperty(NOVELTY_SEARCH, false);
		
		environmentCount = props.getIntProperty(ENVIRONMENT_COUNT);
		environmentReplaceProb = noveltySearchOnly ? 0 : props.getDoubleProperty(ENVIRONMENT_CHANGE_RATE);
		environmentIncreaseRate = noveltySearchOnly ? 0 : props.getDoubleProperty(ENVIRONMENT_INCREASE_RATE);
		environmentCountMax = environmentIncreaseRate > 1 ? props.getIntProperty(ENVIRONMENT_COUNT_MAX) : environmentCount;
		
		if (environmentReplaceProb > 1 && environmentIncreaseRate > 1) {
			throw new IllegalArgumentException(ENVIRONMENT_CHANGE_RATE + " and " + ENVIRONMENT_INCREASE_RATE + " are mutually exclusive.");
		}
		if (noveltySearchOnly && environmentReplaceProb > 1) {
			throw new IllegalArgumentException(ENVIRONMENT_CHANGE_RATE + " and " + NOVELTY_SEARCH_ONLY + " are mutually exclusive.");
		}
		if (noveltySearchOnly && environmentIncreaseRate > 1) {
			throw new IllegalArgumentException(ENVIRONMENT_INCREASE_RATE + " and " + NOVELTY_SEARCH_ONLY + " are mutually exclusive.");
		}
		
		evalType = EvalType.valueOf(props.getProperty(EVAL_TYPE).toUpperCase());
		evalPredictLookahead = props.getIntProperty(EVAL_PREDICT_LOOKAHEAD, 8);
		
		phaseLearnLength = props.getIntProperty(PHASE_LEARN_LENGTH);
		phaseEvalLength = props.getIntProperty(PHASE_EVAL_LENGTH);
		
		nsRecordLength = props.getIntProperty(NOVELTY_SEARCH_RECORD_LENGTH, 8);
		nsStartRecordAtStep = phaseLearnLength + phaseEvalLength - nsRecordLength;
		
		waveCount = props.getIntProperty(WAVE_COUNT_INITIAL);
		
		// Wave count delta and increasing number of environments are mutually exclusive.
		if (environmentIncreaseRate > 1) {
			String deltaString = props.getProperty(WAVE_COUNT_DELTA, "0").trim().toLowerCase();
			boolean isFactor = deltaString.endsWith("x");
			double delta = Double.parseDouble(deltaString.replaceAll("x", ""));
			if (delta >= 1) {
				if (!isFactor || delta > 1) {
					throw new IllegalArgumentException(WAVE_COUNT_DELTA + " and " + ENVIRONMENT_INCREASE_RATE + " are mutually exclusive.");
				}
			}
		}
		
		String[] waveTypeNames = props.getStringArrayProperty(WAVE_TYPES, new String[]{"sine"});
		waveTypes = new WaveType[waveTypeNames.length];
		for (int i = 0; i < waveTypeNames.length; i++) {
			waveTypes[i] = WaveType.valueOf(waveTypeNames[i].toUpperCase());
		}
		
		envRand = new Random(props.getLongProperty(SEED, System.currentTimeMillis()));
		
		environments = new Environment[environmentCountMax];
		for (int e = 0; e < environments.length; e++) {
			environments[e] = new Environment(environmentCounter++);
		}
		
		if (noveltySearchEnabled) {
			noveltySearchEnvCount = noveltySearchOnly ? environmentCount : props.getIntProperty(NOVELTY_SEARCH_ENV_COUNT, environmentCountMax);
			
			// If the same environments aren't used throughout evolution.
			if (environmentReplaceProb > 0) {
				// Create a set of environments (that don't change over the course of evolution) to test novelty on.
				nsEnvironments = new Environment[noveltySearchEnvCount];
				for (int e = 0; e < noveltySearchEnvCount; e++) {
					nsEnvironments[e] = new Environment(-e);
				}
				logger.info("Created " + noveltySearchEnvCount + " environments for novelty search.");
			}
			else {
				if (noveltySearchEnvCount > environmentCountMax) {
					throw new IllegalArgumentException("The number of environments used for novelty search must be less than the (maximum) number used for fitness/performance evaluation when " + ENVIRONMENT_CHANGE_RATE + " = 0.");
				}
			}
			totalNSBehaviourSize = noveltySearchEnvCount * nsRecordLength;
			logger.info("Novelty search behaviours have " + totalNSBehaviourSize + " dimensions.");
		}

		((Properties) props).getEvolver().addEventListener(this);
		
		super.init(props);
	}

	public void initialiseEvaluation() {
		// Create (some) new environments every generation (if environmentReplaceProb > 0).
		for (int e = 0; e < environments.length; e++) {
			if (environmentReplaceProb > random.nextDouble()) {
				environments[e] = new Environment(environmentCounter++);
			}
		}
	}

	@Override
	protected void evaluate(Chromosome genotype, Activator substrate, int evalThreadIndex, double[] fitnessValues, Behaviour[] behaviours) {
		if (nsEnvironments == null) {
			// Evaluate fitness and behaviour on same environments.
			List envs = Arrays.asList(environments).subList(0, Math.max(environmentCount, noveltySearchEnvCount));
			_evaluate(genotype, substrate, null, false, false, fitnessValues, behaviours, envs, environmentCount);
		} else {
			// Evaluate fitness on changing environments and behaviour on fixed novelty search environments.
			_evaluate(genotype, substrate, null, false, false, fitnessValues, null, Arrays.asList(environments).subList(0, environmentCount), 0);
			_evaluate(genotype, substrate, null, false, false, null, behaviours, Arrays.asList(nsEnvironments), 0);
		}
	}
	
	@Override
	public void evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage) {
		_evaluate(genotype, substrate, baseFileName, logText, logImage, null, null, Arrays.asList(environments).subList(0, environmentCount), 0);
		super.evaluate(genotype, substrate, baseFileName, logText, logImage);
	}
	
				  
	public void _evaluate(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage, double[] fitnessValues, Behaviour[] behaviours, List<Environment> envs, int numEnvsToUseForEval) {
		int envCount = envs.size();
		if (numEnvsToUseForEval == 0) {
			numEnvsToUseForEval = envCount;
		}
		
		double rmseAvg = 0;
		NNAdaptor nn = (NNAdaptor) substrate;
		Range nnOutputRange = new Range(nn.getMinResponse(), nn.getMaxResponse());
		boolean scaleOutputForNS = nnOutputRange.getRange() <= 2;
		
		ArrayRealVector behaviour = behaviours != null && behaviours.length > 0 ? new ArrayRealVector(totalNSBehaviourSize) : null;
		
		try {
			NiceWriter logOutput = !logText ? null : new NiceWriter(new FileWriter(baseFileName + ".txt"), "0.000");
			
			for (int envIndex = 0; envIndex < envCount; envIndex++) {
				Environment env = envs.get(envIndex);
				if (logText) {
					logOutput.put("\n\nBEGIN EVALUATION ON " + env + "\n");
				}
	
				// Reset substrate to initial state to begin learning (new) environment.
				substrate.reset();
	
				double envError = 0;
				
				boolean recordBehaviour = envIndex < noveltySearchEnvCount && behaviour != null;
				
				double[] agentInput = new double[1];
				double[] agentOutput = new double[1];
				
				CircularFifoBuffer<Double> agentOutputBuffer = null;
				if (evalType == EvalType.PREDICT) {
					agentOutputBuffer = new CircularFifoBuffer<Double>(evalPredictLookahead);
				}
				// If evalType == REPRODUCE then this is just the current agent output.
				// If it's PREDICT then it's the output of the agent from evalPredictLookahead steps ago.
				double agentOutputBuffered = 0;
				
				// Learning phase.
				for (int step = 0; step < phaseLearnLength; step++) {
					// Get environment output for current step, feed it to agent.
					agentInput[0] = env.getOutput(step);
					nn.next(agentInput, agentOutput);
					
					if (Double.isNaN(ArrayUtil.sum(agentOutput))) {
						double[] agentOut = ((BainNN) nn).getNeuralNetwork().getNeurons().getOutputs();
						System.err.println(ArrayUtil.toString(agentOut, ", ", nf));
						System.err.println(nn);
					}
					
					if (evalType == EvalType.REPRODUCE) {
						agentOutputBuffered = agentOutput[0];
					}
					else {
						if (agentOutputBuffer.isFull()) {
							agentOutputBuffered = agentOutputBuffer.remove();
						}
						agentOutputBuffer.add(agentOutput[0]);
					}
					
					if (logText) logOutput.put("    " + step + "\t" + nf.format(agentInput[0]) + "\t" + nf.format(agentOutputBuffered) + "\n");
				}
				
				if (logText) logOutput.put("    -------------------------\n");
				
				// Evaluation phase.
				if (evalType == EvalType.REPRODUCE) {
					agentInput[0] = -1; // -1 signals reproduce phase.
				}
				for (int step = phaseLearnLength; step < phaseLearnLength + phaseEvalLength; step++) {
					// Get environment and agent output for current step.
					double envOutput = env.getOutput(step);
					nn.next(agentInput, agentOutput);
					
					if (Double.isNaN(ArrayUtil.sum(agentOutput))) {
						double[] agentOut = ((BainNN) nn).getNeuralNetwork().getNeurons().getOutputs();
						System.err.println(ArrayUtil.toString(agentOut, ", ", nf));
						System.err.println(nn);
					}
					
					double error;
					if (evalType == EvalType.REPRODUCE) {
						// Fitness/performance is based on how close the previous agent output is to the environment output. 
						agentOutputBuffered = agentOutput[0];
						error = Math.abs(envOutput - agentOutputBuffered);
					}
					else {
						// Fitness/performance is based on how close the output of the agent from 
						// evalPredictLookahead steps ago is to the current environment output.
						error = 0;
						if (agentOutputBuffer.isFull()) {
							agentOutputBuffered = agentOutputBuffer.remove();
							error = Math.abs(envOutput - agentOutputBuffered);
						}
						agentOutputBuffer.add(agentOutput[0]);
					}
					
					envError += error * error;
					
					if (logText) logOutput.put("    " + step + "\t" + nf.format(envOutput) + "\t" + nf.format(agentOutputBuffered) + "\t" + nf.format(error) + "\n");
					
					if (recordBehaviour && step >= nsStartRecordAtStep) {
						int behaviourIndex = (envIndex * nsRecordLength + (step-nsStartRecordAtStep));
						double outputForB = scaleOutputForNS ? nnOutputRange.translateToUnit(agentOutput[0]) : Range.UNIT.clamp(agentOutput[0]);
						behaviour.setEntry(behaviourIndex, outputForB);
					}
				}
				
				if (envIndex < numEnvsToUseForEval) {
					double rmse = Math.sqrt(envError / phaseEvalLength);
					
					if (logText) logOutput.put("\n  Environment RMSE: " + nf.format(rmse) + "\n");
				
					rmseAvg += rmse;
				}
			}
			
			rmseAvg /= numEnvsToUseForEval;
			
			if (logText) logOutput.close();
			
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		if (fitnessValues != null && fitnessValues.length > 0) {
			fitnessValues[0] = 1.0 / (1 + rmseAvg);
			genotype.setPerformanceValue("0RMSE", rmseAvg);
		}
		
		if (behaviour != null) {
			behaviours[0] = new RealVectorBehaviour(behaviour);
		}
	}
	
	@Override
	public boolean evaluateGeneralisation(Chromosome genotype, Activator substrate, String baseFileName, boolean logText, boolean logImage, double[] fitnessValues) {
		if (genEnvironments == null) {
			// Test on twice as many environments as used for fitness evaluations.
			genEnvironments = new Environment[environmentCountMax*2];
			for (int i = 0; i < environmentCountMax*2; i++) {
				genEnvironments[i] = new Environment(environmentCounter++);
			}
		}
		_evaluate(genotype, substrate, baseFileName, logText, logImage, fitnessValues, null, Arrays.asList(genEnvironments), 0);
		return true;
	}
	
	private boolean increaseDifficulty() {
		String deltaString = props.getProperty(WAVE_COUNT_DELTA, "0").trim().toLowerCase();
		boolean isFactor = deltaString.endsWith("x");
		double delta = Double.parseDouble(deltaString.replaceAll("x", ""));
		if (delta >= 1) {
			int origVal = waveCount;
			if (!isFactor) {
				waveCount += (int) Math.round(delta);
			} else if (delta > 1) {
				waveCount = (int) Math.round(waveCount * delta);
			}
			return waveCount != origVal;
		}
		return false;
	}
	
	private class Environment {
		public int id;
		Wave[] waves;
		double[] output;
		
		public Environment(int id) {
			this.id = id;
			waves = new Wave[waveCount];
			for (int w = 0; w < waveCount; w++) {
				WaveType type = waveTypes[envRand.nextInt(waveTypes.length)];
				//int period =  Math.max(16, phaseLearnLength / 8);
				int period =  envRand.nextInt(Math.max(1, (phaseLearnLength / 8) - 16)) + 16;
				waves[w] = new Wave(type, period, envRand.nextDouble() * Math.PI * 2, 1.0 / waveCount);
			}
			
			output = new double[phaseLearnLength + phaseEvalLength];
			for (int x = 0; x < phaseLearnLength + phaseEvalLength; x++) {
				for (int w = 0; w < waves.length; w++) {
					output[x] += waves[w].getOutput(x);
				}
			}
		}
		
		public double getOutput(int x) {
			return output[x];
		}
		
		public String toString() {
			String out = "Environment " + id;
			for (int w = 0; w < waves.length; w++) {
				out += "\n\t" + waves[w];
			}
			return out;
		}
	}
	
	private class Wave {
		WaveType type;
		int period;
		double phase;
		double amplitude;
		double[] waveTable;
		
		public Wave(WaveType type, int period, double phase, double amplitude) {
			this.type = type;
			this.period = period;
			this.phase = phase;
			this.amplitude = amplitude;
			
			waveTable = new double[period];
			double x = phase;
			for (int i = 0; i < period; i++) {
				waveTable[i] = type.getOutput(x) * amplitude;
				
				x += (2 * Math.PI) / period;
				if (x >= 2 * Math.PI) {
					x -= 2 * Math.PI;
				}
			}
		}
		
		public double getOutput(int x) {
			return waveTable[x % period];
		}
		
		public String toString() {
			return type + " (period=" + period + ", phase=" + phase + ", amplitude=" + amplitude + ")";
		}
	}
	
	public enum WaveType {
		SINE, SQUARE, TRIANGLE, SAW;

		public double getOutput(double x) {
			switch (this) {
			case SINE:
				return (1 + Math.sin(x)) * 0.5;
			case SQUARE:
				return x < Math.PI ? 1 : 0;
			case TRIANGLE:
				return x < Math.PI ? x / Math.PI : 2 - x / Math.PI;
			case SAW:
				return 0.5 * (x / Math.PI); 
			}
			return 0;
		}
	}
	
	
	@Override
	public void ahniEventOccurred(AHNIEvent event) {
		if (event.getType() == AHNIEvent.Type.GENERATION_END) {
			Chromosome bestPerforming = event.getEvolver().getBestPerformingFromLastGen();
			if (targetPerformanceType == 1 && bestPerforming.getPerformanceValue() >= props.getDoubleProperty(DIFFICULTY_INCREASE_PERFORMANCE) 
					|| targetPerformanceType == 0 && bestPerforming.getPerformanceValue() <= props.getDoubleProperty(DIFFICULTY_INCREASE_PERFORMANCE)) {
				if (environmentIncreaseRate > 1) {
					int origEnvCount = environmentCount;
					environmentCount = Math.max(environmentCount + 1, (int) Math.round(environmentCount * environmentIncreaseRate));
					if (environmentCount > environmentCountMax) {
						environmentCount = environmentCountMax;
					}
					if (environmentCount != origEnvCount) {
						logger.info("Increased difficulty. Number of environments to test against is now " + environmentCount + ".");
					}
				}
				else if (increaseDifficulty()) {
					event.getEvolver().logChamp(bestPerforming, true, "");
					
					// Create new environment networks to allow for possibly increased number of waves.
					for (int e = 0; e < environments.length; e++) {
						environments[e] = new Environment(environmentCounter++);
					}
					logger.info("Increased difficulty. Wave count is now " + waveCount + ". All new environments were created.");
				}
			}
		}
	}
	
	@Override
	public int[] getLayerDimensions(int layer, int totalLayerCount) {
		if (layer == 0) // Input layer.
			return new int[] { 1, 1 };
		else if (layer == totalLayerCount - 1) // Output layer.
			return new int[] { 1, 1 };
		return null;
	}
	
	@Override
	public int noveltyObjectiveCount() {
		return noveltySearchEnabled ? 1 : 0;
	}
	
	@Override
	public int fitnessObjectivesCount() {
		return noveltySearchOnly ? 0 : 1;
	}
	
	@Override 
	public String[] objectiveLabels() {
		String[] labels = new String[fitnessObjectivesCount() + noveltyObjectiveCount()];
		int i = 0;
		if (!noveltySearchOnly) labels[i++] = "InvRMSE+1";
		if (noveltySearchEnabled) labels[i++] = "Novelty";
		return labels;
	}
	
	@Override
	public boolean fitnessValuesStable() {
		return false; // environmentReplaceProb == 0;
	}
}
