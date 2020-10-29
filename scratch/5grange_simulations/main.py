import os
import shutil
import multiprocessing

from simulation_model.simulation_scenario_generation import generate_scenarios
from simulation_execution.execute_simulation import execute_simulation


if __name__ == "__main__":
    multiprocessing.freeze_support()

    # Select if you want to generate new simulation scenarios or run manually created ones
    createAndRunScenarios = True

    # Output folder
    baseDir = "E:\\tools\\source\\sims\\"

    # You're supposed to run this script inside the scratch/5grange_simulations folder
    cwd = os.path.abspath(os.getcwd())  # do not touch this

    # Copy simulation binary to baseDir folder
    shutil.copy("../../build/bin/5g_range_demonstration_json", baseDir)

    resultsDict = {"scenario": {}}
    if createAndRunScenarios:
        # 100 batches
        for batch in range(0, 1):  # 100):
            for numUes in [1, ]:  # 2, 5, 10, 20, 50, 100]:
                # Prepare the simulationParameter json files for all simulations
                generate_scenarios(baseDir,
                                  batch,
                                  numUes,
                                  ueSpeeds=[0, ],  # 10, 50, 100],
                                  clusteredUes=[False, ],  # True],
                                  dynamicSpectrumAccess=[False, ],  # True],
                                  markovOptions=[False, ],  # True],
                                  harmonicOptions=[False, ],  # True],
                                  fusionAlgs=[6, ],  # 7, 11, 12, 13],
                                  attackerOptions=[0, ],  # 1, 2, 5],
                                  frequencyBandOptions=[100, ],  # 101, 5, 7],
                                  mimoOptions=[0, ],  # 1, 2]
                                  )

        # Easier than trying to figure out all directories for the individual simulations is to use glob
        # to find all json files with simulation parameters and pass the list for parallel execution
        import glob
        simulationParameterFilesList = glob.glob(baseDir+os.sep+"**"+os.sep+"simulationParameters.json", recursive=True)

        for scenarioJson in simulationParameterFilesList:
            # Before executing anything, we check if the outputs file has been processed for that given scenario
            simulation_path = os.path.dirname(scenarioJson)

            # Run simulation if necessary and try to extract results into a single output file
            execute_simulation(simulation_path, baseDir)


        # When all simulations have finished, load up their results and apply some statistics/plots
        # Result files were pickled and compressed

    pass