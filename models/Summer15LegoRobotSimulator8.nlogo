extensions [ ahninn ]

breed [robots robot]
breed [turrets turret]

globals [ goal-x goal-y found-goal?  found-goal-tick
  ROBOT_CENTER_TO_FRONT_BUMPER_LENGTH
  ROBOT_CENTER_TO_TURRET_LENGTH
  ROBOT_BACK_EDGE_TO_TURRET_LENGTH
  ROBOT_CENTER_TO_BACK_EDGE_LENGTH
  ROBOT_WHEEL_EDGE_TO_EDGE_WIDTH
  
  walls
  north-walls
  east-walls
  south-walls
  west-walls
  northeast-walls
  southeast-walls
  southwest-walls
  northwest-walls
]
patches-own [ wall? is-north-wall? is-east-wall? is-south-wall? is-west-wall? is-goal? ]
robots-own [ 
  my-neural-net-brain
  my-turret 
  bump-sensor-pressed? 
  distance-sensor-data-array 
  action-queue 
  time-to-next-action 
 ]

to setup
  clear-all

  set ROBOT_CENTER_TO_FRONT_BUMPER_LENGTH 1.1 ; patches
  set ROBOT_CENTER_TO_TURRET_LENGTH 1.0 ; patches
  set ROBOT_BACK_EDGE_TO_TURRET_LENGTH 0.5 ; patches
  set ROBOT_CENTER_TO_BACK_EDGE_LENGTH ROBOT_CENTER_TO_TURRET_LENGTH + ROBOT_BACK_EDGE_TO_TURRET_LENGTH ; patches
  set ROBOT_WHEEL_EDGE_TO_EDGE_WIDTH 1.5 ; patches
  
  set found-goal? false
  set found-goal-tick -1
  setup-walls
  setup-goal
  setup-robots
  reset-ticks
end

to setup-walls
  ask patches [ set wall? false set is-goal? false
                set is-north-wall? false set is-east-wall? false set is-south-wall? false set is-west-wall? false ] ; normal patches
  ask patches with [ (abs pxcor = max-pxcor or abs pycor = max-pycor) ] [
    set wall? true
    set pcolor brown
  ]
;  ask patches with [ pxcor = 0 ] [
  ask patches with [ pxcor = 0 and pycor <= 0 ] [
    set wall? true
    set pcolor brown
  ]
  ask patches with [ wall? ]
  [
    set is-north-wall? any? neighbors4 with [ not wall? and pycor < [pycor] of myself ]
    set is-east-wall? any? neighbors4 with [ not wall? and pxcor < [pxcor] of myself ]
    set is-south-wall? any? neighbors4 with [ not wall? and pycor > [pycor] of myself ]
    set is-west-wall? any? neighbors4 with [ not wall? and pxcor > [pxcor] of myself ]
  ]
  ask patches with [ wall? ] [
    let east-west-neighbors (patch-set (patch-at -1 0) (patch-at 1 0))
    let north-south-neighbors (patch-set (patch-at 0 -1) (patch-at 0 1))
    if any? east-west-neighbors with [is-north-wall?] [ set is-north-wall? true ]
    if any? east-west-neighbors with [is-south-wall?] [ set is-south-wall? true ]
    if any? north-south-neighbors with [is-west-wall?] [ set is-west-wall? true ]
    if any? north-south-neighbors with [is-east-wall?] [ set is-east-wall? true ]
  ]
  set walls patches with [ wall? ]
  set north-walls patches with [ is-north-wall? ]
  set east-walls patches with [ is-east-wall? ]
  set south-walls patches with [ is-south-wall? ]
  set west-walls patches with [ is-west-wall? ]
  set northeast-walls (patch-set north-walls east-walls)
  set northwest-walls (patch-set north-walls west-walls)
  set southeast-walls (patch-set south-walls east-walls)
  set southwest-walls (patch-set south-walls west-walls)
end
to setup-goal
  ifelse move-goal? [
    set goal-x (random 21) - 21.5
    set goal-y (random 21) - 21.5
  ][
    set goal-x -11.5
    set goal-y -11.5
  ]
  if (flip-horiz?) [ set goal-x goal-x * -1 ]

  ask patches with [ (abs (pxcor - goal-x) < 1) and (abs (pycor - goal-y) < 1) ]
  [
    set pcolor white
    set is-goal? true
  ]
end
to setup-robots
  let robot-start-x 0.5 + 1.2  ;0.5 is the edge of the wall, plus 12 cm over  
  
  let num-robots-to-create num-robots
  if (random-start-locations?) [ set num-robots-to-create 8 ] ;; if randomized, create all 8, & remove some after
  repeat num-robots-to-create [
    create-robots 1 [
      set my-neural-net-brain ahninn:create-from-xml xml ; create artificial neural network

      set ycor -22.5 + 1 + ROBOT_CENTER_TO_TURRET_LENGTH; -22.5 is edge of wall, + start line is 10 cm out.
      set xcor robot-start-x
      if (flip-horiz?) [ set xcor xcor * -1 ]
      set robot-start-x robot-start-x + 2.8  ; 28 cm between robots on the starting line
      set color gray + 1
      set size 2
      set shape "lego_robot"
      set heading 0
      set bump-sensor-pressed? false
      set distance-sensor-data-array []
      set action-queue []
      set time-to-next-action 0
      robot-enqueue-first-scan ; robot starts by scanning for distance measurements
      robot-add-action-to-queue (task [ robot-make-angle-decision ]) 0 ; then choosing a direction
      
      hatch-turrets 1 [ 
        ask myself [ set my-turret myself ]
        set color gray - 2
        set size 1
        set shape "lego_turret"
        bk ROBOT_CENTER_TO_TURRET_LENGTH
      ]
      create-link-to my-turret [ tie hide-link ]
      if (robot-trails?) [
        pen-down
      ]
    ]
  ]
  if random-start-locations? [
    ask n-of (8 - num-robots) robots [ ask my-turret [die] die ]
  ]
end

to load-xml-file
;  user-message "Choose chromosome xml file"

 ; set-current-directory "../ahni-augustana-summer-2015-robot-project/data_output"
  file-open user-file
  set xml ""
  while [not file-at-end?] [
    set xml word xml (file-read-characters 1000)
  ]
  file-close
end

to-report potentially-visible-walls-for-robot-angle [ angle ]
  if wall-vision-level = 2 [
    if angle >= 0 and angle < 90 [ report northeast-walls ]
    if angle >= 90 and angle < 180 [ report southeast-walls ]
    if angle >= 180 and angle < 270 [ report southwest-walls ]
    if angle >= 270 and angle < 360 [ report northwest-walls ]  
  ]
  if wall-vision-level = 1 [
    if angle > 335 or angle < 25 [ report north-walls ]
    if angle >= 25 and angle <= 65 [ report northeast-walls ]
    if angle > 65 and angle < 115 [ report east-walls ]
    if angle >= 115 and angle <= 155 [ report southeast-walls ]
    if angle > 155 and angle < 205 [ report south-walls ]
    if angle >= 205 and angle <= 245 [ report southwest-walls ]
    if angle > 245 and angle < 295 [ report west-walls ]
    if angle >= 295 and angle <= 335 [ report northwest-walls ]  
  ]
  if (wall-vision-level = 0) [
    if angle > 320 or angle < 40 [ report north-walls ]
    if angle >= 40 and angle <= 50 [ report northeast-walls ]
    if angle > 50 and angle < 130 [ report east-walls ]
    if angle >= 130 and angle <= 140 [ report southeast-walls ]
    if angle > 140 and angle < 220 [ report south-walls ]
    if angle >= 220 and angle <= 230 [ report southwest-walls ]
    if angle > 230 and angle < 310 [ report west-walls ]
    if angle >= 310 and angle <= 320 [ report northwest-walls ]  
  ]
end

to go
  if found-goal? and stop-when-found-goal? [ stop ]
  foreach (sort-on [time-to-next-action] robots) [
    ask ? [ 
      while [time-to-next-action <= 0] [
        if robot-action-queue-is-empty? [
          robot-enqueue-full-scan ; reset to initial state of starting a full scan
          robot-add-action-to-queue (task [ robot-make-angle-decision]) 0
        ]
        run robot-fetch-next-task-from-queue
        if (bump-sensor-pressed?) [ 
          set bump-sensor-pressed? false
          robot-clear-action-queue
          robot-enqueue-backward10 
          if (rotate-after-bump?) [
            robot-enqueue-rotate (135 + random 45)
          ]
        ]
      ]
    ]
  ]
  ask robots [ set time-to-next-action time-to-next-action - time-increment]
  tick
end


to robot-enqueue-forward40 
  let total-time-for-40cm random-normal 2.036 0.04  ;; from robot calibration data
  let straight-dist random-normal 38.2 3.06 ;; from calibration data, robots tended to move a little short, with some variation

  let perpendicular-drift random-normal 0 3.39 ;; from calibration data, robots don't move straight, so we need to account for drift/curviture
  if (veer-left?) [ set perpendicular-drift perpendicular-drift + 2.11 ]
  
  let dist sqrt (straight-dist ^ 2 + perpendicular-drift ^ 2)
  let drift-angle (atan perpendicular-drift straight-dist)
  robot-add-action-to-queue (task [ left drift-angle ]) 0
  let num-steps (ceiling dist)
  let time-per-cm (total-time-for-40cm / num-steps)
  let cm-dist dist / num-steps
  repeat num-steps [
    robot-add-action-to-queue (task [ robot-forward-about-one-cm cm-dist]) time-per-cm
  ]
end

to robot-enqueue-backward10
  let total-time-for-10cm random-normal 1.774 0.144 ; from robot calibration data
  let time-per-cm total-time-for-10cm / 10
  repeat 10 [
    robot-add-action-to-queue (task [ robot-backward-one-cm ]) time-per-cm
  ]
end

to robot-enqueue-rotate [ angle ]
  let rotation-time (random-normal (0.0169 * (abs angle) + 0.3525) 0.049289) ; best-fit from calibration data
  if angle = 0 [
    set rotation-time (random-normal 0.012 0.007)  ; special case when angle is 0... only a tiny pause here
  ]
  set angle random-normal angle 1.7 ;; noisy turn angle (based on robot calibration data)
  let rotations-for-animation (ceiling (rotation-time / time-increment))
  if (rotations-for-animation < 1) [ set rotations-for-animation 1 ]
  repeat rotations-for-animation [
    robot-add-action-to-queue (task [ left angle / rotations-for-animation ]) (rotation-time / rotations-for-animation)
  ]
end

to robot-enqueue-full-scan
 
  robot-add-action-to-queue (task [ set distance-sensor-data-array [] robot-sense-distance-and-turn]) random-normal 0.5613 0.15365 ; from robot calibation
  
  repeat 11 [
    robot-add-action-to-queue (task [ robot-sense-distance-and-turn ]) random-normal 0.5613 0.15365 ; from robot calibation
  ]
  robot-add-action-to-queue (task [ ask my-turret [ left 360 ] ]) random-normal 1.39 0.1 ; from robot calibation
end

to robot-enqueue-first-scan ;; first time through needs some special handling
  
  robot-add-action-to-queue (task [right (random-normal 0 2)]) 0  ; robots' start angles aren't perfectly straight
  
  robot-add-action-to-queue (task [ set distance-sensor-data-array [] robot-sense-distance-and-turn]) random-normal 1 0.4
  
  repeat 11 [
    robot-add-action-to-queue (task [ robot-sense-distance-and-turn]) random-normal 0.5613 0.15365 ; from robot calibation
  ]
  robot-add-action-to-queue (task [ ask my-turret [ left 360 ] ]) random-normal 1.39 0.1 ; from robot calibation

  if (mangle-first-scan?) [
    ;; the robots seemed to get faulty readings and choose odd headings...
    ;; make the first scan data faulty, based on empirical observation of robot behavior...
    robot-add-action-to-queue (task mangle-distance-sensor-array) 0
  ]
end

to mangle-distance-sensor-array 
  let choice (random 100)
  if (choice < 31) [ set distance-sensor-data-array replace-item 0 distance-sensor-data-array 0 ]  ; we observed a 31% chance of turning 30 right    
  if (choice < 37) [ set distance-sensor-data-array replace-item 1 distance-sensor-data-array 0 ]  ; we observed 6% chance of turning 30 left
end

to robot-add-action-to-queue [ tsk time ]
  set action-queue lput (list tsk time) action-queue
end

to robot-clear-action-queue
  set action-queue []
end

to-report robot-action-queue-is-empty?
  report empty? action-queue
end

to-report robot-fetch-next-task-from-queue 
  let next-pair first action-queue
  set action-queue but-first action-queue
  let tsk (item 0 next-pair)
  let time (item 1 next-pair)
  set time-to-next-action time-to-next-action + time
;;  show (word (precision time 2) " " tsk)  ;; DEBUG
  report tsk
end

to robot-forward-about-one-cm [ cm-dist ]  ; cm-dist should be close to 1.0 (but could be a little more/less)
  let patch-dist cm-dist / 10
    ifelse (obstacle-ahead (patch-dist + ROBOT_CENTER_TO_FRONT_BUMPER_LENGTH)) or (obstacle-ahead 0.5)
    [  set bump-sensor-pressed? true stop  ]
    [  forward patch-dist   ]
    if is-goal? and not found-goal? [ set found-goal? true set found-goal-tick ticks]    
end

to robot-backward-one-cm 
  if not (obstacle-ahead (-0.1 - ROBOT_CENTER_TO_BACK_EDGE_LENGTH))
  [
    back 0.1
  ]
end

to robot-make-angle-decision
  if (length distance-sensor-data-array) != 12 [
    error (word "PROBLEM: distance sensor array only has " (length distance-sensor-data-array))
  ]
  let angle 0 
  ifelse decision-mode = "neural_net" [
    set angle angle-choice-neural-net
  ][ ifelse decision-mode = "human" [
    set angle angle-choice-human-designed
  ][ ifelse decision-mode = "always_forward" [
    set angle 0
  ][ if decision-mode = "random" [
    set angle 179 - random 360
  ]]]]
  
  robot-enqueue-rotate angle
  robot-enqueue-forward40
end

to-report angle-choice-human-designed
  if (item 0 distance-sensor-data-array) > 1 [
    report 0
  ]
  
  let index 0
  ifelse (reverse-scan-order-for-human?) [
    set index (position (max distance-sensor-data-array) (reverse distance-sensor-data-array))    
    set index (length distance-sensor-data-array) - 1 - index
  ] [
    set index (position (max distance-sensor-data-array) distance-sensor-data-array)
  ]
  
  let angle index * -30
  if (angle < -180) [
    set angle angle + 360
  ]
  report angle
end

to-report angle-choice-neural-net
  let normed-sensor-data map [ ? / 10] distance-sensor-data-array
  let nn-output first (ahninn:next my-neural-net-brain normed-sensor-data)
;  print (word "out: " (precision nn-output 1)) ;; TODO: DEBUG: remove this
  let angle-choice (nn-output * 360) mod 360 - 180
  report angle-choice  
end

;; NOTE: negative dist-ahead means behind the robot!
to-report obstacle-ahead [ dist-ahead ]
  let target-patch (patch-ahead dist-ahead)
      ; ask target-patch [ set pcolor green ]
  let checking-robot self
  if (target-patch = nobody or [wall? or any? robots-here with [ self != checking-robot]] of target-patch) [ report true ]
  report false
end

;to robot-rotate [ angle ] ; unnecessary
;  left angle 
;end

to robot-sense-distance-and-turn
  let sensor-result robot-sense-distance
  set distance-sensor-data-array lput sensor-result distance-sensor-data-array
  ask my-turret [ right 30 ]
end

;; collects the distance sensor reading (in meters, like the real robots) for the current turret heading 
to-report robot-sense-distance
  debug-flash self blue "look"
  let sensor-result 100 ; 100 patches = 10 m is close enough to "infinity", given this robot course size...
    ask my-turret [
      let visible-robots no-turtles
      ifelse (better-turtle-vision?) [
        set visible-robots (turtle-set (robots in-cone 25 13)
                                     (robots in-cone 9 55 )
                                     (robots in-cone 4 80))        
;        set visible-robots (turtle-set ((robots in-cone 25 13) with [ (random 100 < 70)])
;                                     (robots in-cone 8 49 )
;                                     (robots in-cone 3 86))
      ][
        set visible-robots (turtle-set ((robots in-cone 25 13) with [ (random 100 < 70)])
                                     (robots in-cone 8 49 )
                                     (robots in-cone 3 86))
      ]
      set visible-robots visible-robots with [ my-turret != myself ] ;; don't include the robot who's currently sensing
      if any? visible-robots [
        let closest-robot min-one-of visible-robots [ distance myself ]
        set sensor-result distance closest-robot
        debug-flash closest-robot cyan "saw"
      ]
      ;ask walls [ set pcolor gray ]
      let visible-patches (patch-set (patches in-cone 25 10) (patches in-cone 5 30)) 
      let visible-walls visible-patches with [ member? self potentially-visible-walls-for-robot-angle [heading] of myself ]
      debug-flashp visible-patches white "."
      if any? visible-walls [
        debug-flashp visible-walls magenta "x"
        let nearest-wall min-one-of visible-walls [ distance myself ]
        debug-flashp nearest-wall yellow "O"
        let nearest-wall-dist distance nearest-wall
        if (nearest-wall-dist < sensor-result) [ set sensor-result nearest-wall-dist ]
      ]
    ]
    set sensor-result sensor-result / 10  ; convert patches to meters
    debug-flash self blue (word (precision sensor-result 2) " m")
    report sensor-result
end

;to-report robot-sense-touch
  ;; if any? robots in-cone X Y [ report true ]
  ;; if any? patches in-cone Z W [ report true ]
;  report false
;end

to-report robot-sense-goal?
  report [is-goal?] of patch-here
end

to debug-flash [ turts flash-color msg ]
  if (DEBUG?) [
    ask turts [ 
      let old-color color
      set color flash-color
      set label msg
      display
      wait debug-speed
      set color old-color
      set label ""
      display
    ]
  ]
end

to debug-flashp [ pats flash-color msg ]
  if (DEBUG?) [
    ask pats [ 
     ; set pcolor flash-color
      set plabel-color flash-color
      set plabel msg
    ]
    display
    wait debug-speed
    ask pats [
;      set pcolor gray
      set plabel ""
    ]
    display
  ]
end


to-report evaluate-fitness
;  random-seed 1234 ;; TODO DEBUG REMOVE
  setup
  repeat 2400 [ go ]

  ;; actual goal?
  let closest-robot-dist min [ distancexy goal-x goal-y ] of robots
  report 1 - closest-robot-dist / ((sqrt 2) * (world-width - 2))  ; normalized value between 0 (worst) and 1 (best)
  
  ;report ((max [ ycor ] of robots) + 22.5) / 45 ;; goal:upwards  TODO: DEBUG: REMOVE
;  report ((mean [ xcor ] of robots) + 22.5) / 45 ;; goal:rightward  TODO: DEBUG: REMOVE

;  let avg-robot-dist mean [ distancexy goal-x goal-y ] of robots
;  report 1 - avg-robot-dist / ((sqrt 2) * (world-width - 2))  ; normalized value between 0 (worst) and 1 (best)

end


to-report novelty-get-normalized-center-of-mass-x
  report (mean [ xcor ] of robots - (min-pxcor + 0.5)) / (world-width - 2)
end

to-report novelty-get-normalized-center-of-mass-y
  report (mean [ ycor ] of robots - (min-pycor + 0.5)) / (world-width - 2)
end

to-report novelty-get-normalized-dispersion
  report (mean [ mean [distance myself] of other robots ] of robots) / ((sqrt 2) * (world-width - 2))
end

;to-report temp-dispersion
;  ask robots [ move-to one-of patches with [ not wall? and not any? robots-here ] ]
;  report novelty-get-normalized-dispersion
;end
;
;to-report temp-xcenter
;  ask robots [ move-to one-of patches with [ not wall? and not any? robots-here ] ]
;  report novelty-get-normalized-center-of-mass-x
;end
;to-report temp-ycenter
;  ask robots [ move-to one-of patches with [ not wall? and not any? robots-here ] ]
;  report novelty-get-normalized-center-of-mass-y
;end

;to-report timetest 
;  reset-timer 
;  setup 
;  repeat 2400 [ go ]
;  report timer
;end
;
@#$#@#$#@
GRAPHICS-WINDOW
391
8
871
509
23
23
10.0
1
10
1
1
1
0
0
0
1
-23
23
-23
23
1
1
1
ticks
30.0

BUTTON
28
249
102
283
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
41
433
196
503
xml
String representation of best performing substrate from final generation:\n9098\nNeuron count: 14\nSynapse count: 4\nTopology type: Feed-forward\n\nNeurons:\n		type	func	bias\n	0	i	linear	0.0\n	1	i	linear	0.0\n	2	i	linear	0.0\n	3	i	linear	0.0\n	4	i	linear	0.0\n	5	i	linear	0.0\n	6	i	linear	0.0\n	7	i	linear	0.0\n	8	i	linear	0.0\n	9	o	linear	0.0\n	10	h	sigmoid	0.0\n	11	i	linear	0.0\n	12	i	linear	0.0\n	13	i	linear	0.0\n\nConnections:\n	pre > post	weight\n	i:7 > o:9	0.6515910029411316\n	i:11 > o:9	0.13572432100772858\n	h:10 > o:9	0.6989704370498657\n	i:6 > h:10	0.9510630369186401\n\n\nString representation of Chromosome:\n<org.jgapcustomised.ChromosomeMaterial>\n  <primaryParentId>8368</primaryParentId>\n  <secondaryParentId>8543</secondaryParentId>\n  <m__alleles>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1013</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1014</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1015</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1016</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1017</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1018</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1019</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1020</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1021</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1022</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1023</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1024</innovationId>\n        <type>INPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>1025</innovationId>\n        <type>OUTPUT</type>\n        <activationType>linear</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.ConnectionAllele>\n      <gene class=\"com.anji.neat.ConnectionGene\">\n        <innovationId>1031</innovationId>\n        <srcNeuronId>1023</srcNeuronId>\n        <destNeuronId>1025</destNeuronId>\n      </gene>\n      <connectionGene reference=\"../gene\"/>\n      <weight>0.6515909936890173</weight>\n    </com.anji.neat.ConnectionAllele>\n    <com.anji.neat.ConnectionAllele>\n      <gene class=\"com.anji.neat.ConnectionGene\">\n        <innovationId>1075</innovationId>\n        <srcNeuronId>1013</srcNeuronId>\n        <destNeuronId>1025</destNeuronId>\n      </gene>\n      <connectionGene reference=\"../gene\"/>\n      <weight>0.13572431570899646</weight>\n    </com.anji.neat.ConnectionAllele>\n    <com.anji.neat.NeuronAllele>\n      <gene class=\"com.anji.neat.NeuronGene\">\n        <innovationId>2043</innovationId>\n        <type>HIDDEN</type>\n        <activationType>sigmoid</activationType>\n      </gene>\n      <neuronGene reference=\"../gene\"/>\n      <bias>0.0</bias>\n    </com.anji.neat.NeuronAllele>\n    <com.anji.neat.ConnectionAllele>\n      <gene class=\"com.anji.neat.ConnectionGene\">\n        <innovationId>2044</innovationId>\n        <srcNeuronId>1022</srcNeuronId>\n        <destNeuronId>2043</destNeuronId>\n      </gene>\n      <connectionGene reference=\"../gene\"/>\n      <weight>0.9510630214249374</weight>\n    </com.anji.neat.ConnectionAllele>\n    <com.anji.neat.ConnectionAllele>\n      <gene class=\"com.anji.neat.ConnectionGene\">\n        <innovationId>2045</innovationId>\n        <srcNeuronId>2043</srcNeuronId>\n        <destNeuronId>1025</destNeuronId>\n      </gene>\n      <connectionGene reference=\"../gene\"/>\n      <weight>0.6989704408375459</weight>\n    </com.anji.neat.ConnectionAllele>\n  </m__alleles>\n  <shouldMutate>false</shouldMutate>\n  <pruned>false</pruned>\n</org.jgapcustomised.ChromosomeMaterial>                                                                                                                                                                                                                                                                                                                                                                                                                                                                
1
1
String

BUTTON
113
249
177
283
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
26
527
157
560
DEBUG?
DEBUG?
1
1
-1000

SLIDER
26
571
258
604
debug-speed
debug-speed
0.0
1.0
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
22
207
211
240
time-increment
time-increment
0
2
0.1
0.1
1
sec
HORIZONTAL

MONITOR
194
248
287
293
mins
ticks * time-increment / 60
1
1
11

TEXTBOX
39
364
211
439
During evolution, the xml inputbox gets set automatically for each genotype being evaluated.
12
0.0
1

SLIDER
19
8
144
41
num-robots
num-robots
1
8
8
1
1
NIL
HORIZONTAL

CHOOSER
150
9
312
54
decision-mode
decision-mode
"neural_net" "human" "always_forward" "random"
0

SWITCH
6
112
187
145
better-turtle-vision?
better-turtle-vision?
0
1
-1000

SWITCH
394
550
526
583
veer-left?
veer-left?
1
1
-1000

SWITCH
602
548
772
581
rotate-after-bump?
rotate-after-bump?
1
1
-1000

SLIDER
189
112
342
145
wall-vision-level
wall-vision-level
0
2
2
1
1
NIL
HORIZONTAL

SWITCH
392
513
587
546
mangle-first-scan?
mangle-first-scan?
1
1
-1000

SWITCH
600
513
889
546
reverse-scan-order-for-human?
reverse-scan-order-for-human?
1
1
-1000

SWITCH
162
529
296
562
robot-trails?
robot-trails?
1
1
-1000

SWITCH
173
160
308
193
move-goal?
move-goal?
1
1
-1000

SWITCH
32
160
165
193
flip-horiz?
flip-horiz?
1
1
-1000

SWITCH
35
297
268
330
stop-when-found-goal?
stop-when-found-goal?
0
1
-1000

BUTTON
205
450
317
483
NIL
load-xml-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
20
57
254
90
random-start-locations?
random-start-locations?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lego_robot
true
0
Rectangle -7500403 true true 45 75 255 345
Polygon -7500403 true true 45 75 150 30 255 75 45 75
Rectangle -11221820 true false 15 15 285 30

lego_turret
true
0
Polygon -7500403 true true 45 45 90 240 210 240 255 45 180 45 180 150 120 150 120 45
Circle -2674135 true false 45 10 76
Circle -2674135 true false 180 9 76

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="compare_human_naive" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;always_forward&quot;"/>
      <value value="&quot;human&quot;"/>
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="compare_human_options" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>(word veer-left? "_" better-vision?)</metric>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-vision?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="compare_vision3" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>(word veer-left? "_" better-vision?)</metric>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-vision?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="compare_vision4" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>(word veer-left? "_" better-vision?)</metric>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-vision?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="compare_vision5" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>(word veer-left? "_" better-vision?)</metric>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
      <value value="&quot;always_forward&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-vision?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="new_compare_human_vision" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>(word veer-left? "_tv" better-turtle-vision? "_wv" wall-vision-level)</metric>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rotate-after-bump?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wall-vision-level">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-turtle-vision?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test_reverse_scan_order" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="num-robots">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rotate-after-bump?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="better-turtle-vision?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mangle-first-scan?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reverse-scan-order?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wall-vision-level">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test-num-robots-for-human" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reverse-scan-order-for-human?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-robots" first="1" step="1" last="8"/>
    <enumeratedValueSet variable="better-turtle-vision?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mangle-first-scan?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-trails?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wall-vision-level">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rotate-after-bump?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test-num-robots-for-human-orig-scan" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks * time-increment / 60 &gt; 200</exitCondition>
    <metric>ticks * time-increment / 60 ; minutes</metric>
    <enumeratedValueSet variable="time-increment">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reverse-scan-order-for-human?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-robots" first="1" step="1" last="8"/>
    <enumeratedValueSet variable="better-turtle-vision?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mangle-first-scan?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="robot-trails?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wall-vision-level">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="veer-left?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rotate-after-bump?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decision-mode">
      <value value="&quot;human&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
