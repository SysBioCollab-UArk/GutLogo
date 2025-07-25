breed [bifidos bifido] ;; define the Bifidobacteria breed
breed [desulfos desulfo] ;; define the Desulfovibrio breed
breed [closts clost] ;; define the Clostridia breed
breed [bacteroides bacteroid];; define the bacteroides bacteroidus breed
turtles-own [age doubConst energy excrete flowConst isSeed isStuck remAttempts]
patches-own [glucose FO lactose lactate inulin CS glucosePrev FOPrev lactosePrev
lactatePrev inulinPrev CSPrev glucoseReserve FOReserve lactoseReserve lactateReserve
inulinReserve CSReserve avaMetas stuckChance]
globals [trueAbsorption negMeta testState result]


to display-labels
;; Shows levels of energy on the turtles in the viewer
  ask turtles [set label ""]
  ask desulfos [set label round energy ]
  ask bifidos [set label round energy ]
  ask closts [set label round energy ]
end


to setup

  ;; ensure the model starts from scratch
  clear-all

  ;; Initializing the turtles and patches
	;; populates the world with the bacteria population at the initial-numbers set by the user
  set-default-shape bifidos "dot"
  create-bifidos (initNumBifidos * (1 - seedPercent / 100)) [
    ;;create non-seeds
    set color blue
    set size 0.25
    set label-color blue - 2
    set energy 100
    set excrete false
    set isSeed false
    set isStuck true
    set age random 1000
	  set flowConst 1 ;; can use this to edit the breed specfic flow distance
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

    create-bifidos (initNumBifidos * (seedPercent / 100)) [
    ;;create seeds
    set color blue
    set size 0.25
    set label-color blue - 2
    set energy 100
    set excrete false
    set isSeed true
    set isStuck true
    set age random 1000
	  set flowConst 1 ;; can use this to edit the breed specfic flow distance
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

  set-default-shape desulfos "dot"
  create-desulfos (initNumDesulfos * (1 - seedPercent / 100)) [
    ;;create non-seeds
    set color green
    set size 0.25
    set energy 100
    set excrete false
    set isSeed false
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

  create-desulfos (initNumDesulfos * (seedPercent / 100)) [
    ;;create seeds
    set color green
    set size 0.25
    set energy 100
    set excrete false
    set isSeed true
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

  set-default-shape closts "dot"
  create-closts (initNumClosts * (1 - seedPercent / 100)) [
    ;;create non-seeds
    set color red
    set size 0.25
    set energy 100
    set excrete false
    set isSeed false
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

    create-closts (initNumClosts * (seedPercent / 100)) [
    ;;create seeds
    set color red
    set size 0.25
    set energy 100
    set excrete false
    set isSeed true
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

  set-default-shape bacteroides "dot"
  create-bacteroides (initNumBacteroides * (1 - seedPercent / 100)) [
    ;;create non-seeds
    set color grey
    set size 0.25
    set energy 100
    set excrete false
    set isSeed false
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

  create-bacteroides (initNumBacteroides * (seedPercent / 100)) [
    ;;create seeds
    set color grey
    set size 0.25
    set energy 100
    set excrete false
    set isSeed true
    set isStuck true
	  set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy random-xcor random-ycor
  ]

	;; initializes the patch variables
  ask patches [
    set glucose 0
    set FO 0
    set lactose 0
    set lactate 0
    set inulin 0
    set CS 0
    set glucosePrev 0
    set FOPrev 0
    set lactosePrev 0
    set lactatePrev 0
    set inulinPrev 0
    set CSPrev 0
    set glucoseReserve 0
    set FOReserve 0
    set lactoseReserve 0
    set lactateReserve 0
    set inulinReserve 0
    set CSReserve 0
    set stuckChance 0
  ]

  ;; setup the true absorption rate
  setTrueAbs

  ;; setup the stuckChance
  setStuckChance

  ;; Setup for stop if negative metas
  set negMeta false

  ;; set time to zero
  reset-ticks

  ;; reset the testState
  set testState 0

end


to go
;; This function determines the behavior at each time tick

  ;; stop if error or unexpected output
  stopCheck

  ;; Modify the energy level of each turtle and metabolite level of each patch
  ask patches [
    patchEat
    storeMetabolites
  ]
  ;; make meta must be in seperate ask, sequential tasks
  ask patches[
    makeMetabolites
  ]

  ;; agents do their other procedures for this tick
  bactTickBehavior

  ;; set the new stuckChance for the patches
  setStuckChance

  ;; change the trueAbsorption
  setTrueAbs

  ;; make agents into seeds
  createSeeds

  ;; Probiotics or bacteria in
  bactIn

  ;; Increment time
  tick

end


to stopCheck
;; code for stopping the simulation on unexpected output

  ;; Stop if negative number of metas calculated
  if negMeta [stop]

  ;; Stop if any population hits 0 or there are too many turtles
  if (count turtles > 1000000) [ stop ]
  if not any? turtles [ stop ] ;; stop if all turtles are dead
end


to setStuckChance
;; controls stuckChance, function of patch population, linear function into asymptote
  ask patches[
    let population count(turtles-here)
    ;; 1 - exponential-like function
    set stuckChance (maxStuckChance - ((maxStuckChance) * population / (midStuckConc + population)))
    if stuckChance < lowStuckBound [set stuckChance 0];; lower bound
  ]
end


to createSeeds
;; controls whether an agent becomes a seed or not
;; first checks if the agent is stuck or not
  ask patches[
    ask turtles-here[
      if (isStuck and (random 100 < seedChance))[
        set isSeed true
      ]
    ]
  ]
end


to setTrueAbs
  ;; controls the true absorption rate

  ;; 0.723823204 is the weighted average immune response coefficient calculated for
  ;; Healthy bacteria gut percentages. This allows the absorption to change due to
  ;; bacteria populations, simulating immune response.

	ifelse (any? turtles)[
  	set trueAbsorption absorption / 100 * (0.723823204 / ((0.8 * ((count desulfos) / (count turtles))) +
  	(1 * ((count closts) / (count turtles)))+(1.2 * ((count bacteroides) / (count turtles))) +
  	(0.7 * ((count bifidos) / (count turtles)))))

    set trueAbsorption min list trueAbsorption 1
	][
		set trueAbsorption 0
		print "ERROR! Bacteria died out. Problem with simulation leading to inaccurate results. Terminating Program."
	]
end


to bactIn
  ;; controls when probiotics enter system
  if ticks mod tickInflow = 0[
    inConc
  ]
end


;; Each of these functions are currently equivalent, different function so we can expand on it if needed
to deathBifidos
;; Bifidobacteria die if below the energy threshold or if excreted
  if energy <= 0[
    die
  ]
  if excrete [die]
end


to deathClosts
;; Clostrida die if below the energy threshold or if excreted
  if energy <= 0 [
    die
  ]
  if excrete [die]
end


to deathDesulfos
;; Desulfovibrio die if below the energy threshold or if excreted
  if energy <= 0 [
    die
  ]
  if excrete [die]
end


to deathbacteroides
;; bacteroides die if below energy threshold or if excreted
  if energy <= 0 [
    die
  ]
  if excrete [die]
end


to makeMetabolites
;; Runs through all the metabolites and makes them, and moves them.
  let frac (flowDist - (floor( flowDist )))

  let span ((max-pycor - min-pycor) + 1)

  let leftDist (pxcor - min-pxcor)

  if ((inulin < 0) or (CS < 0) or (FO < 0) or (lactose < 0) or (lactate < 0) or (glucose < 0)) [
    print "ERROR! Patch reported negative metabolite. Problem with simulation leading to inaccurate results. Terminating Program."
    set negMeta true
    stop
  ]

  set inulin ((inulin) + inulinReserve)
  set FO ((FO) + FOReserve)
  set lactose ((lactose) + lactoseReserve)
  set lactate ((lactate) + lactateReserve)
  set glucose ((glucose) + glucoseReserve)
  set CS ((CS) + CSReserve)

  let remainFactor 0
  if (flowDist < 1)[set remainFactor (1 - flowDist)]
  set inulin (inulin * remainFactor)
  set FO (FO * remainFactor)
  set lactose (lactose * remainFactor)
  set lactate (lactate * remainFactor)
  set glucose (glucose * remainFactor)
  set CS (CS * remainFactor)

  ;;The leftmost pacthes evenly split the inFlow number of metas
  ifelse (leftDist < flowDist)[
    let inFlowCoef (((min list 1 (flowDist - leftDist))) / (flowDist * span))
    set inulin ((inulin) + (inFlowInulin * inFlowCoef))
    set FO ((FO) + (inFlowFO * inFlowCoef))
    set lactose ((lactose) + (inFlowLactose * inFlowCoef))
    set lactate ((lactate) + (inFlowLactate * inFlowCoef))
    set glucose ((glucose) + (inFlowGlucose * inFlowCoef))
    set CS ((CS) + (inFlowCS * inFlowCoef))
  ]
  [
    let added ( ((get-inulin (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-inulin (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (inulin + added) < 1000[
      set inulin (inulin + (added))
    ]
		[
			set inulin (1000)
		]

    set added ( ((get-FO (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-FO (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (FO + added) < 1000[
      set FO (FO + (added))
    ]
		[
			set FO (1000)
		]

    set added ( ((get-lactose (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-lactose (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (lactose + added) < 1000[
      set lactose (lactose + (added))
    ]
		[
			set lactose (1000)
		]

    set added ( ((get-lactate (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-lactate (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (lactate + added) < 1000[
      set lactate (lactate + (added))
    ]
		[
			set lactate (1000)
		]

    set added ( ((get-glucose (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-glucose (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (glucose + added) < 1000[
      set glucose (glucose + (added))
    ]
		[
			set glucose (1000)
		]

    set added ( ((get-CS (- (ceiling flowDist)) 0) * (min list frac (1 - remainFactor))) + ((get-CS (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (CS + added) < 1000[
      set CS (CS + (added))
    ]
		[
			set CS (1000)
		]
  ]

;;Need to handle case of patch which flowDist ends in from beginning
  if(leftDist = (floor flowDist))[
    let added ( ((get-inulin (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (inulin + added) < 1000[
      set inulin (inulin + (added))
    ]
		[
			set inulin (1000)
		]

    set added ( ((get-FO (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (FO + added) < 1000[
      set FO (FO + (added))
    ]
		[
			set FO (1000)
		]

    set added ( ((get-lactose (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (lactose + added) < 1000[
      set lactose (lactose + (added))
    ]
		[
			set lactose (1000)
		]

    set added ( ((get-lactate (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (lactate + added) < 1000[
      set lactate (lactate + (added))
    ]
		[
			set lactate (1000)
		]

    set added ( ((get-glucose (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (glucose + added) < 1000[
      set glucose (glucose + (added))
    ]
		[
			set glucose (1000)
		]

    set added ( ((get-CS (- (floor flowDist)) 0) * (min list (1 - frac) (floor flowDist))) )
    ifelse (CS + added) < 1000[
      set CS (CS + (added))
    ]
		[
			set CS (1000)
		]
  ]

  if ((inulin < 0.001)) [
    set inulin 0
  ]

	if ((CS < 0.001)) [
		set CS 0
	]

	if ((FO < 0.001)) [
		set FO 0
	]

	if ((lactose < 0.001)) [
		set lactose 0
	]

	if ((lactate < 0.001)) [
		set lactate 0
	]

	if ((glucose < 0.001)) [
		set glucose 0
	]

	ifelse (((max-pxcor - min-pxcor) < 1))[
		set inulinReserve (0)
  	set FOReserve (0)
  	set lactoseReserve (0)
  	set lactateReserve (0)
  	set glucoseReserve (0)
  	set CSReserve (0)
	][
  	set inulinReserve ((inulin) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
  	set FOReserve ((FO) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
  	set lactoseReserve ((lactose) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
  	set lactateReserve ((lactate) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
  	set glucoseReserve ((glucose) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
  	set CSReserve ((CS) * reserveFraction / 100 * ((max-pxcor - pxcor)/(max-pxcor - min-pxcor)))
	]

  	set inulin ((inulin - inulinReserve) * (1 - trueAbsorption))
  	set FO ((FO - FOReserve) * (1 - trueAbsorption))
  	set lactose ((lactose - lactoseReserve) * (1 - trueAbsorption))
  	set lactate ((lactate - lactateReserve) * (1 - trueAbsorption))
  	set glucose ((glucose - glucoseReserve) * (1 - trueAbsorption))
  	set CS ((CS - CSReserve) * (1 - trueAbsorption))
end


to storeMetabolites
;; Sets previous metaohydrate variables to current levels to allow for correct
;; transfer on ticks
  set inulinPrev ((inulin + inulinReserve))
  set FOPrev ((FO + FOReserve))
  set lactosePrev ((lactose + lactoseReserve))
  set lactatePrev ((lactate + lactateReserve))
  set glucosePrev ((glucose + glucoseReserve))
  set CSPrev ((CS + CSReserve))
end


to bactTickBehavior
;; reproduce the chosen turtle
  ask bifidos [
    flowMove ;; movement of the bacteria by flow
  ;;randMove ;; movement of the bacteria by a combination of motility and other random forces
    checkStuck ;; check if the bacteria becomes stuck or unstuck
    deathBifidos ;; check that the energy of the bacteria is enough, otherwise bacteria dies
    if (age mod bifidoDoub = 0 and age != 0)[ ;;this line controls on what tick mod reproduce
      reproduceBact ;; run the reproduce code for bacteria
    ]
  	set age (age + 1) ;; increase the age of the bacteria with each tick
  ]

  ask desulfos [;;controls the behavior for the desulfos bacteria
    flowMove
  ;;randMove
    checkStuck
    deathDesulfos
    if (age mod desulfoDoub = 0 and age != 0)[
      reproduceBact
    ]
  	set age (age + 1)
  ]

  ask closts [;;controls the behavior for the closts
    flowMove
  ;;randMove
    checkStuck
    deathClosts
    if (age mod clostDoub = 0 and age != 0)[
      reproduceBact
    ]
  	set age (age + 1)
  ]

  ask bacteroides [;;controls the behavior for the bacteroides
    flowMove
  ;;randMove
    checkStuck
    deathbacteroides
    if (age mod bacteroidDoub = 0 and age != 0)[
      reproduceBact
    ]
  	set age (age + 1)
  ]

end


to reproduceBact
;; reproduce the chosen turtle
  if energy > 50 and count turtles-here < 1000[ ;;turtles-here check to model space limit
    let tmp (energy / 2 )
    set energy (tmp) ;; parent's energy is halved
    hatch 1 [
      rt random-float 360
      set energy tmp ;; child gets half of parent's energy
      set isSeed false
      set isStuck false
	    set age 0
    ]
  ]
end


to randMove
;; DISABLED
;; Defines random movement of turtles
;; rotates the orientation of the bacteria randomly within 180 degrees front-facing then moves forward the bacteria's randDist
;; if it would hit go through the simulation boundaries, sets excrete to true
  if (isStuck = false)[
    rt (random 360)

    ifelse (can-move? randDist)
      [fd randDist]
      [set excrete true]
  ]

end


to flowMove
;; moves the bacteria by the flow distance * the bacteria's flow constant
;; if xcor would pass the max-pxcor with movement, sets excrete to true
  if (isStuck = false and isSeed = false)[
    ifelse (xcor + flowDist * flowConst >= (max-pxcor + 0.5))
      [set excrete true]
      [set xcor (xcor + flowDist * flowConst)]
  ]

end


to checkStuck
;; checks if the bacteria should be stuck or unstucked based on the chances
  ifelse(not isStuck and (random-float 100 < stuckChance))[
    set isStuck true
  ]
  [;;else
    if(isStuck and (random-float 100 < unstuckChance))[
      set isStuck false
    ]
  ]
end


to inConc
;; controls the amount of each type of bacteria flowing in to the simulation
;; similar to the code in go, but bacteria are now placed at only in the first column

  create-bifidos inConcBifidos [
    set color blue
    set size 1
    set label-color blue - 2
    set energy 100
    set excrete false
    set isSeed false
    set isStuck false
    set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy min-pxcor - 0.5 random-ycor

  ]

  create-desulfos inConcDesulfos [
    set color green
    set size 1
    set energy 100
    set excrete false
    set isSeed false
    set isStuck false
    set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy min-pxcor - 0.5 random-ycor

  ]

  create-closts inConcClosts [
    set color red
    set size 1
    set energy 100
    set excrete false
    set isSeed false
    set isStuck false
    set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy min-pxcor - 0.5 random-ycor

  ]
  create-bacteroides inConcBacteroides [
    set color grey
    set size 1
    set energy 100
    set excrete false
    set isSeed false
    set isStuck false
    set age random 1000
	  set flowConst 1
	  set doubConst 1
    setxy min-pxcor - 0.5 random-ycor

  ]
end


to bactEat [metaNum]
;; run this through a turtle with a metaNum parameter to have them try to eat the carb

  if (metaNum = 10)[;;CS
    ifelse (breed = desulfos)[;; check correct breed
      set energy (energy + 50);; increase the energy of the bacteria
      ask patch-here [
          set CS (CS - 1);; reduce the meta count
        if (CS < 1)[;; remove the meta from avaMetas if there is no more of it
          set avaMetas remove 10 avaMetas
        ]
      ]
    ]
    [;;else
      ;;do nothing
    ]
  ]

  if (metaNum = 11)[;;FO
    ifelse (breed = closts or breed = bacteroides)[
      set energy (energy + 25)
      ask patch-here [
        set FO (FO - 1)
        if (FO < 1)[
          set avaMetas remove 11 avaMetas
        ]
      ]
    ]
    [;;else
      if(breed = bifidos)[
        set energy (energy + 50)
        ask patch-here [
          set FO (FO - 1)
          if (FO < 1)[
            set avaMetas remove 11 avaMetas
          ]
        ]
        ask patch-here [
          set lactate (lactate + bifido-lactate-production)
        ]
      ]
    ];;end else
  ]

  if (metaNum = 12)[;;GLUCOSE
    ifelse (breed = closts or breed = bacteroides)[
      set energy (energy + 50)
      ask patch-here [
        set glucose (glucose - 1)
        if (glucose < 1)[
          set avaMetas remove 12 avaMetas
        ]
      ]
    ]
    [;;else
      if (breed = bifidos) [
        set energy (energy + 25)
        ask patch-here [
        	set glucose (glucose - 1)
          if (glucose < 1)[
            set avaMetas remove 12 avaMetas
          ]
        ]
        ask patch-here [
          set lactate (lactate + bifido-lactate-production)
        ]
      ]
    ];;end else
  ]

  if (metaNum = 13)[;;INULIN
    ifelse (breed = closts or breed = bacteroides)[
      set energy (energy + 25)
      ask patch-here [
        set inulin (inulin - 1)
        if (inulin < 1)[
          set avaMetas remove 13 avaMetas
        ]
      ]
    ]
    [;;else
      if (breed = bifidos) [
      set energy (energy + 25)
        ask patch-here [
          	set inulin (inulin - 1)
          if (inulin < 1)[
            set avaMetas remove 13 avaMetas
          ]
        ]
        ask patch-here [
          set lactate (lactate + bifido-lactate-production)
        ]
      ]
    ];;end else
  ]

  if (metaNum = 14)[;;LACTATE
    ifelse (breed = (desulfos))[
      set energy (energy + 50)
      ask patch-here [
        set lactate (lactate - 1)
        if (lactate < 1)[
          set avaMetas remove 14 avaMetas
        ]
      ]
    ]
    [;;else
      ;;do nothing
    ]
  ]

  ifelse (metaNum = 15)[;;LACTOSE
    ifelse (breed = closts or breed = bacteroides)[
      ifelse (breed = closts)[
        set energy (energy + 25)
      ]
      [;;else
        set energy (energy + 50)
      ];;end else
      ask patch-here [
        set lactose (lactose - 1)
        if (lactose < 1)[
          set avaMetas remove 15 avaMetas
        ]
      ]
    ]
    [;;else
      if (breed = bifidos) [
        set energy (energy + 50)
        ask patch-here [
          	set lactose (lactose - 1)
          if (lactose < 1)[
            set avaMetas remove 15 avaMetas
          ]
        ]
        ask patch-here [
          set lactate (lactate + bifido-lactate-production)
        ]
      ]
    ];;end else
  ]
  [;;else
    ;;do nothing
  ]
end

to patchEat
;; run this on a ask patches to have them start the turtle eating process
  ask turtles-here [
    set remAttempts 2 ;; reset the number of attempts
    set energy (energy - (100 / 1440)) ;; decrease the energy of the bacteria, currently survive 24 hours no eat
  ]
  let allMetas (list CS FO glucose inulin lactate lactose);; list containing numbers of all the metas
  set avaMetas []

  ;; initialize the two lists
  let hungryBact (turtles-here with [(energy < 80) and (remAttempts > 0)])
  let i 0
  while [i < (length(allMetas))][
    if (item i allMetas >= 1) [
      set avaMetas lput (i + 10) avaMetas
    ]
    set i (i + 1)
  ]
  let iter 0 ;; used to limit the number of times the next while loop will occur, aribitrary
  ;; do the eating till no metas or not hungry
  while [(length(avaMetas) > 0) and any? hungryBact and iter < 100] [
    ;; code here to randomly select a turtle from hungryBact and then ask it to run bactEat with a random meta from ava. list
    ask one-of hungryBact [
      bactEat(one-of avaMetas)
      set remAttempts remAttempts - 1
    ]
    ;;re-bound agent set
    set hungryBact (turtles-here with [(energy < 80) and (remAttempts > 0)])

    set iter (iter + 1)
  ]
end

to-report getAllBactPatchLin
;; Returns a list of the number of bacteria on each patch
;; Only works properly with a world with height of 1
  let data map getNumBactLin (range min-pxcor (max-pxcor + 1))
  report (data)
end

to-report getNumBactLin [xVal]
;; Returns the number of bacteria on the patch at given x-coord
;; Only works properly with a world with height of 1
  report [count(turtles-here)] of patch xVal 0
end

to-report getNumSeeds
;; Returns the number of bacteria with isSeed set to true
  report count turtles with [isSeed = true]
end

to-report getStuckChance [xVal]
;; Needed to run JUnit tests
  report [stuckChance] of patch xVal 0
end

to-report getTrueAbs
;; Needed to run JUnit tests
  report trueAbsorption
end

to-report getResult
;; Needed to run JUnit tests
  report result
end

;; CarbReporters

to-report get-glucose [target-patch-x-coord target-patch-y-coord]
;; Returns glucose value at passed coordinate
    report [glucosePrev] of patch-at target-patch-x-coord target-patch-y-coord
end


to-report get-lactose [target-patch-x-coord target-patch-y-coord]
;; Returns lactose value at passed coordinate
    report [lactosePrev] of patch-at target-patch-x-coord target-patch-y-coord
end


to-report get-inulin [target-patch-x-coord target-patch-y-coord]
;; Returns inulin value at passed coordinate
    report [inulinPrev] of patch-at target-patch-x-coord target-patch-y-coord
end


to-report get-lactate [target-patch-x-coord target-patch-y-coord]
;; Returns lactate value at passed coordinate
    report [lactatePrev] of patch-at target-patch-x-coord target-patch-y-coord
end


to-report get-FO [target-patch-x-coord target-patch-y-coord]
;; Returns FO value at passed coordinate
    report [FOPrev] of patch-at target-patch-x-coord target-patch-y-coord
end


to-report get-CS [target-patch-x-coord target-patch-y-coord]
;; Returns CS value at passed coordinate
    report [CSPrev] of patch-at target-patch-x-coord target-patch-y-coord
end


;; Experiments, used in the cluster runs to control the simulation

;; note that these controllers won't actually work on ticks not multiple of 100 because of how BehaviorSpace is set up
to flowRateTest
;; changes the flowrate by testConst after at S-S then reduces it after a week of time
  if (ticks >= 10080 and testState = 0)[
    set flowDist (flowDist * testConst)
    set testState 1
  ]
  if (ticks >= 20160 and testState = 1)[
    set flowDist (flowDist / testConst)
    set testState 2
  ]
end

to glucTest
;; changes the CS inConc for carb experiment
  if (ticks >= 10080 and testState = 0)[
    set inFlowGlucose (inFlowGlucose * testConst)
    set testState 1
  ]
  if (ticks >= 20160 and testState = 1)[
    set inFlowGlucose (inFlowGlucose / testConst)
    set testState 2
  ]
end

to bifidosTest
;; changes inConcBifidos for probiotic experiment
  if (ticks >= 10080 and testState = 0)[
    set inConcBifidos (5000 * testConst)
    set testState 1
  ]
  if (ticks >= 20160 and testState = 1)[
    set inConcBifidos (0)
    set testState 2
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
7
53
5015
112
-1
-1
50.0
1
10
1
1
1
0
0
1
1
0
99
0
0
1
1
1
ticks
30.0

BUTTON
18
10
82
43
Setup
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

BUTTON
96
10
159
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1014
119
1417
435
Populations
Time
Populations
0.0
10.0
0.0
10.0
true
true
"ifelse plots-on? [\nauto-plot-on\n]\n[auto-plot-off]" ""
PENS
"Closts" 1.0 0 -2674135 true "" "plot count closts"
"Bifidos" 1.0 0 -13345367 true "" "plot count bifidos"
"Desulfos" 1.0 0 -10899396 true "" "plot count desulfos"
"Bacteroides" 1.0 0 -7500403 true "" "plot count bacteroides"

MONITOR
89
458
163
503
Cloststridia
count closts
17
1
11

MONITOR
163
458
251
503
Bifidobacteria
count bifidos
17
1
11

MONITOR
251
458
336
503
Desulfovibrio
count desulfos
17
1
11

MONITOR
1
503
132
548
Percentage Clostridia
100 * count closts / count turtles
2
1
11

MONITOR
132
503
287
548
Percentage Bifidobacteria
100 * count bifidos / count turtles
2
1
11

MONITOR
287
503
438
548
Percentage Desulfovibrio
100 * count desulfos / count turtles
2
1
11

MONITOR
1
458
90
503
Total Bacteria
count turtles
3
1
11

MONITOR
633
458
690
503
Glucose
sum [glucose] of patches
0
1
11

MONITOR
576
458
633
503
FO
sum [FO] of patches
2
1
11

MONITOR
462
458
519
503
Lactate
sum [lactate] of patches
2
1
11

MONITOR
690
458
747
503
CS
sum [CS] of patches
2
1
11

MONITOR
405
458
462
503
Inulin
sum [inulin] of patches
2
1
11

MONITOR
519
458
576
503
Lactose
sum [Lactose] of patches
2
1
11

MONITOR
336
458
405
503
Bacteroides
count bacteroides
17
1
11

MONITOR
438
503
582
548
Percentage Bacteroides
100 * count bacteroides / count turtles
2
1
11

SWITCH
1014
435
1120
468
plots-on?
plots-on?
0
1
-1000

INPUTBOX
627
179
753
239
inConcBacteroides
0.0
1
0
Number

INPUTBOX
627
239
753
299
inConcBifidos
0.0
1
0
Number

INPUTBOX
753
179
885
239
inConcClosts
0.0
1
0
Number

INPUTBOX
753
239
885
299
inConcDesulfos
0.0
1
0
Number

INPUTBOX
1450
177
1577
237
randDist
0.0
1
0
Number

INPUTBOX
627
299
753
359
tickInflow
480.0
1
0
Number

INPUTBOX
162
178
317
238
initNumBifidos
23562.0
1
0
Number

INPUTBOX
162
238
317
298
initNumBacteroides
5490.0
1
0
Number

INPUTBOX
162
298
317
358
initNumClosts
921.0
1
0
Number

INPUTBOX
162
358
317
418
initNumDesulfos
70.0
1
0
Number

TEXTBOX
687
154
834
184
Flow Variables
20
0.0
1

TEXTBOX
377
152
570
183
Metabolite Variables
20
0.0
1

TEXTBOX
1489
237
1557
288
randFlow Variables\n(Disabled)
14
0.0
1

TEXTBOX
176
152
317
181
Initial Bacteria
20
0.0
1

TEXTBOX
15
129
156
179
Bacteria Reproduction
20
0.0
1

MONITOR
582
503
684
548
gutPerm
trueAbsorption
6
1
11

INPUTBOX
7
178
162
238
bifidoDoub
330.0
1
0
Number

INPUTBOX
7
238
162
298
desulfoDoub
330.0
1
0
Number

INPUTBOX
7
358
162
418
clostDoub
330.0
1
0
Number

INPUTBOX
7
298
162
358
bacteroidDoub
330.0
1
0
Number

INPUTBOX
317
178
472
238
inFlowInulin
10.0
1
0
Number

INPUTBOX
317
298
472
358
inFlowFO
25.0
1
0
Number

INPUTBOX
472
298
627
358
inFlowLactose
15.0
1
0
Number

INPUTBOX
472
238
627
298
inFlowLactate
0.0
1
0
Number

INPUTBOX
472
178
627
238
inFlowGlucose
30.0
1
0
Number

INPUTBOX
317
238
472
298
inFlowCS
0.1
1
0
Number

INPUTBOX
317
358
472
418
bifido-lactate-production
0.005
1
0
Number

INPUTBOX
1350
435
1417
495
testConst
1.0
1
0
Number

INPUTBOX
885
277
1015
337
midStuckConc
10.0
1
0
Number

SLIDER
162
417
317
450
seedPercent
seedPercent
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
472
358
627
391
absorption
absorption
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
885
212
1015
245
unstuckChance
unstuckChance
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
885
179
1015
212
lowStuckBound
lowStuckBound
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
885
337
1015
370
seedChance
seedChance
0
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
753
299
883
332
flowDist
flowDist
0
4
0.28
0.01
1
NIL
HORIZONTAL

SLIDER
885
245
1015
278
maxStuckChance
maxStuckChance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
472
391
627
424
reserveFraction
reserveFraction
0
100
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
904
126
1002
176
Stuck Variables\n
20
0.0
1

@#$#@#$#@
#GutLogo Documentation
This document contains information on how to use the model and how it functions. One can search for specific information about a component by using the find tool from the edit option tab.

#Copyright and other information

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Model summary
This model is a framework for the simulation of bacteria populations in the human gut. By default, the model is tuned and set to model the ileum of the small intestine and bacteria correlated to Autism Spectrum Disorders. High levels of Desulfovibrio and Clostridium and low levels of Bifidobacterium have been found in the gut of children with ASDs. Therefore, a gut microbiome dominated by Bifidobacteria is likely to be that of a healthy child, whereas a gut microbiome dominated by Desulfovibrio and/or Clostridium is likely to be that of an autistic child. The framework can be expanded to model any number of bacterial species or conditions and provide an initial estimation of how conditions affect the populations.

# How to use the interface
The GutLogo simulator makes use of the NetLogo interface. The model comes with default values that match our control simulations. A user can begin the simulation by clicking the setup and then the go buttons. The long bar underneath the buttons will visualize the current condition of the gut. The plot on the right will display the populations of the bacterial species in the gut. When testing conditions, be sure to allow the simulation to reach an equilibrium-like state before inducing a perturbation. 

The left block of inputs control the doubling times of the bacterial species. Feedback loops have not yet been implemented. Therefore, widely different doubling times will lead to an unstable simulation. The inital bacteria column of inputs control the colonies that initially populate the gut. The 'initNum' variables control the initial values for each respective species while the 'seedPercent' determines the fraction of colonies permanently affixed to the gut lining. 

The center two columns control variables affecting the metabolites in the model. The 'inFlow' variables alter the amount of each metabolite that enters the simulation each tick. The amount of lactate produced by bifidobacteria can be altered by 'bifido-lactate-production'. Absorption and 'reserveFraction' were both disabled for the experiments done in this paper. Absorption represents the percentage of metabolites that pass through the gut into the bloodstream. An absorption check is done every tick and the percentage of metabolite is removed. A 'reserveFraction' of greater than zero will activate the reserve metabolite module of the simulation. This module inhibits the bacteria from accessing a portion of the metabolites. The portion of metabolite avaliable is a function of position down the gut. Therefore, a colony further down the gut would have access to a larger portion of the remaining bacteria than a colony closer to the start.

The next section of inputs are variables dealing with the fluid flow and probiotics of the simulation. The 'inConc' inputs determine the amount of each species of bacteria that will enter the simulation. The 'tickInflow' variable controls how often bacteria enter the gut. The default setting of 480 ticks corresponds to every 8 hours. The 'flowDist' slider controls the flow rate throughout the gut, the value is in computational patches. The default value of 0.28 patches reflects the average flow rate in the small intestine. The volumetric flow rate of the small intestine is between 2.5 and 20 ml/min. This averages out to 11.25ml/min or 11.25 cc/min. The diameter of the small intestine is approximately 1 in. or 2.54 cm. This means the cross-sectional area is 5.07 sq. cm. Therefore, the lateral flow rate of the small intestine is 2.22 cm/min. Since the circumference of the small intestine is then 7.98 cm., the area a patch represents is a 7.98 cm by 7.98 cm square. As only 1-dimensional flow is being modeled, it would take one simulated minute (one tick) for the metabolites and bacteria to move  2.22/7.98 or .278 of a patch length.

The final section of inputs consists of variables controlling the chances a bacteria can become embedded in the gut lining and not be affected by the fluid flow. The 'lowStuckBound' is the lower bound that stuck chance can be, any lower and it will be rounded down to 0. 'UnstuckChance' is the chance that a bacteria can be dislodged from the gut lining and once again be affected by the fluid flow. 'MaxstuckChance' and 'midStuckConc' are the inputs to the exponential-like function controlling 'stuckChance'. 'SeedChance' is the probability that a colony already in the gut lining becomes a permanent member, never to become dislodged.

One can use the Behaviorspace module to schedule multiple simulations in parallel by clicking the tools option and selecting Behaviorspace. Several of the experiments done in this paper are available for editing in the interface. 

# Variables


##turtle breeds

**bacteroides**:  The bacteroid breed of turtles, agentset that contains all of the bacteroid
turtle types.

**bifidos**: The bifidobacteria breed of turtles, agentset that contains all of the Bifidobacterium

**closts**:  The clostridia breed of turtles, agentset that contains all of the Clostridium

**desulfos**: The desulfovibrio breed of turtles, agentset that contains all of the Desulfobrivios


##turtle types

**bacteroid**: The generic bacteroides type.

**bifido**: The generic bifidobacteria type.

**clost**: The generic clostridia type.

**desulfo**: The generic desulfovibrio type.


##turtles-own

**age**: Positive integer value representing the number of ticks the bacteria has been alive for. Used to determine if a bacteria would reproduce on the current tick. Seed colony bacteria are given a random age from 0 to 1000.

**doubConst**: A floating point value that can be used to modify the doubling time of a bacteria. This value is multiplied by the bacterial doubling times inputted to get the tick mod on which bacteria can reproduce.

**energy**: Floating point number used to represent the health of a bacteria. The energy of a bacteria is reduced by a set amount each tick and increased when the bacteria consumes food. During reproduction, half of the energy of a parent bacteria is transferred to the child .

**excrete**: Boolean value that notes if a bacteria would exit the simulation. If set true, the bacteria will die on the next call of death-”bacteriaName”. If false, no effect.

**flowConst**: A floating point value used to account for possible differences in flow rate depending on bacterial species. This value is multiplied by the flowDist to calculate the distance that a bacteria will travel on a tick.

**isSeed**: Boolean value noting if a bacteria is a seed colony. Seed colonies do not move with the flow and are permanently stuck to the wall.

**isStuck**: Boolean value noting if a bacteria is currently stuck to the wall, bacteria stuck to the wall will not move with the flow.

**remAttempts**: Positive integer value used to keep track of the number of attempts provided to the bacteria to consume some food source. Limits the maximum number of attempts a bacteria can make each tick.

**stuckChance**: Floating point value tracking the percent chance a bacteria will become ‘stuck’. Set by the setStuckChance function.


##patches-own

**avaMetas**: Mutating list of the integers 10 through 15. Each int represents a food source that is available in the current patch. When every metabolite is available, the list will be [10 11 12 13 14 15]. If no metabolite is available, the list will be empty. This is used in the eating code so only food sources that are available will be presented to bacteria.

**CS**: Floating point value that represents the number of chondroitin sulfate units that are available for the bacteria to consume

**CSPrev**: Floating point value that represents the number of chondroitin sulfate units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**CSReserve**: Floating point value representing the number of chondroitin sulfate units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases

**FO**: Floating point value that represents the number of fructooligosaccharide units that are available for the bacteria to consume

**FOPrev**: Floating point value that represents the number of fructooligosaccharide units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**FOReserve**: Floating point value representing the number of fructooligosaccharide units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases

**glucose**: Floating point value that represents the number of glucose units that are available for the bacteria to consume

**glucosePrev**: Floating point value that represents the number of glucose units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**glucoseReserve**: Floating point value representing the number of glucose units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases

**inulin**: Floating point value that represents the number of inulin units that are available for the bacteria to consume

**inulinPrev**: Floating point value that represents the number of inulin units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**inulinReserve**: Floating point value representing the number of inulin units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases

**lactate**: Floating point value that represents the number of lactate units that are available for the bacteria to consume

**lactatePrev**: Floating point value that represents the number of lactate units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**lactateReserve**: Floating point value representing the number of lactate units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases

**lactose**: Floating point value that represents the number of lactose units that are available for the bacteria to consume

**lactosePrev**: Floating point value that represents the number of lactose units that were in a given patch before the movement phase of a given tick. (Used to safely update patch values)

**lactoseReserve**: Floating point value representing the number of lactose units that are in a given patch but at that tick bacteria are unable to consume. This value will decrease as the x-coordinate increases


##globals

**negMeta**: Boolean value set to true if a patch ever has a negative number of a metabolite. Used to terminate program w/o an error popup.

**trueAbsorption**: The actual absorption based on the user-entered absorption and the relative population percentages of the different bacteria. This represents the fraction of metabolites each patch absorbs each tick.

**negMeta**: Boolean value set to true if a patch ever has a negative number of a metabolite. Used to terminate program w/o an error popup.

**testState**: Postive integer value that tracks which state the experiment is in. Used exclusively in the automatic experiment testing.

**result**: For running the JUnit tests.


##Function Documentation:

**display-labels**:
Function Type: 	Procedure
Input:			None
Output:		None
Purpose:		Shows levels of energy on the turtles in the viewer
Description:		Energies displayed are rounded. Bacteroides energies not displayed

**setup**:
Function Type: 	Procedure
Input:			None
Output:		None
Purpose:		Initializes the simulation based on the global variables’ values.
Description:		Populates the world with seed bacteria placed randomly and initializes all variables not given by user. Sets initial trueAbsorption value and resets the tick counter. Resets the simulation completely when run.

**go**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Runs the simulation
Description:		This function is executed at the start of each tick. Calls all of the relevant functions in order and then increments the tick counter.

**stopCheck**:
Function Type:	Procedure
Input:			None
Output:		None, can print error messages
Purpose:		Determine if simulation needs to terminate and terminates it
Description:		This function can be used to stop the simulation automatically and needs to be called in the go function.

**setStuckChance**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		controls the stuckChance variable for every patch
Description:		Modifies stuck chance based on an 1 - exponential function of population. This function is specified by the midStuckConc variable and the maxStuckChance variable. Additionally, if the result of the function is considered low enough, the stuckChance is set to zero.

**createSeeds**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Make some stuck bacteria into seeds
Description:		If the bacteria is already stuck and will not become unstuck, determines if that the bacteria will become a seed.

**setTrueAbs**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Controls the actual rate of absorption
Description:		Adds the weighted percentages of each of the bacteria together and divides an ideal result by the sum. Modifies the user-input value for absorption by a factor equal to this quotient. The ideal value is based on qualitative approximations to how the body reacts to each of the four currently modeled bacteria. This was made to represent the potential inflammatory response to the existence of the various bacteria. By setting the absorption to 0, this function is in effect disabled as well as any incorporation of absorption to the model. This is the default setting.

**bactIn**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Controls when bacteria enter the system.
Description:		Has an if statement that takes the mod of the tick count wrapped around a call to inConc. Defaults to allowing inConc to be called every tick.

**death-bifidos**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask bifidos’
Output:		None
Purpose:		Removes dead bifidobacteria from model
Description:		Called as part of bacteria behavior. Will have bacteria die if energy is less than or equal to 0 or if excreted.

**death-closts**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask closts’
Output:		None
Purpose:		Removes dead clostridia from model
Description:		Called as part of bacteria behavior. Will have bacteria die if energy is less than or equal to 0 or if excreted.

**death-desulfos**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask desulfos’
Output:		None
Purpose:		Removes dead desulfovibrios from model
Description:		Called as part of bacteria behavior. Will have bacteria die if energy is less than or equal to 0 or if excreted.

**death-bacteroides**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask bacteroides’
Output:		None
Purpose:		Removes dead bacteroides from model
Description:		Called as part of bacteria behavior. Will have bacteria die if energy is less than or equal to 0 or if excreted.

**make-metabolites**:
Function Type:	Procedure
Input:			Must be called on a patch, e.g. via ‘ask patches’
Output:		None
Purpose:		Moves metabolites through the model
Description:		Multipart function. Given a patch, it first removes an amount of each metabolite equal to the fraction that would not leave the patch assuming the metabolite was evenly spread out in the given patch. It then determines the amount of each metabolite that flows into the patch either from the patches before it or from the inflow into the model. During this process, it uses the helper ‘get-<metabolite>’ functions which provide the total amount of the given metabolite at the start of the tick on which this function was called. In this process, an amount of each metabolite can be reserved based on x-coordinate as well as a user-input global variable. The default setting is 0, so this will not occur unless altered. Additionally, absorption by the body may be accounted for in this function by altering the absorption global variable. However, the default setting is to not account for this as the default value for absorption is 0.

**store-metabolites**:
Function Type: 	Procedure
Input:			Must be called on a patch, e.g. via ‘ask patches’
Output:		None
Purpose:		Ensures ‘<metabolite>Prev’ variables are up to date.
Description: 		Helper function for make-metabolites. Sets ‘<metabolite>Prev’ variables to current levels to allow for correct transfer between patches.

**bacteria-tick-behavior**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Controls the behavior of each bacterial species.
Description:		Call the flowMove, randMove, checkStuck, and death functions each tick. Then runs the reproduction code when the age of the bacteria matches a multiple of the doubling time. Finally increases the age of the bacteria.

**reproduceBact**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask turtles’
Output:		None
Purpose:		If the bacteria called on is of age, reproduce
Description:		Creates a new bacteria from the parent bacteria with half of the the parent’s energy. The parent’s energy will be halved and its energy must be greater than a half to reproduce. The child bacteria will never be a seed or stuck, its age will be 0.

**randMove**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask turtles’
Output:		None
Purpose:		Defines the random movement of the bacteria.
Description:		DISABLED. This random movement accounts for the turbulence in the flow, motility of the bacteria, and other similar movements. Moves the bacteria in a random direction by the length of the randDist variable.

**flowMove**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask turtles’
Output:		None
Purpose:		Move bacteria due to flow in gut
Description:		Moves the bacteria of down the intestine by the flow distance multiplied by the bacteria’s flow constant. If the bacteria would move past the bounds of the simulation, the excrete boolean of the bacteria is set to true. 

**checkStuck**:
Function Type:	Procedure
Input:			Must be called on an agent, e.g. via ‘ask turtles’
Output:		None
Purpose:		Determine whether or not a given agent becomes stuck/unstuck
Description:		Checks if the bacteria will become stuck or unstuck depending on the user-input values of the global variables.

**inConc**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		Control the amount of bacteria flowing into the simulation
Description:		This can be used to simulate probiotics or bacteria from earlier sections of the intestine. Creates bacteria on the the minimum x-coord and a random y-coord. The bacteria have a random age between 0 and 1000 and are not seeds or stuck.

**bactEat**:
Function Type:	Procedure
Input:			metaNum, Must be called on an agent, e.g. via ‘ask turtles’
Output:		None
Purpose:		Feed the bacteria agents
Description:		This code is run through an agent and passed a metabolite number from avaMeta. If the species of the bacteria can process the metabolite, then the energy of the bacteria is increased. Then the metabolite counts in that patch is decreased and if the metabolite count would be reduced below 1, the metabolite is removed from avaMetas. Called through patchEat.

**patchEat**:
Function Type:	Procedure
Input:			must be called on a patch, e.g. via ‘ask patches’
Output:		None
Purpose:		Controls the bacteria eating process on the current patch.
Description:		Initializes the remAttempts for all of the bacteria on the patch and then decreases the energy of the bacteria. Then initializes the allMetas, avaMetas, and hungryBact lists. While there are avaMetas and there are any hungryBact chooses one of the avaMetas and then a hungryBact and runs the bactEat code on that bacteria and then decreases its remAttempts. At the end of the while, the hungryBact list is reinitialized to remove bacteria that have eaten or have no more attempts. This loops until there are no more hungryBact or metabolites.

**getAllBactPatchLin**:
Function Type:	Reporter
Input:			None
Output:		List of the number of bacteria on each patch
Purpose:		Used to help collect data in BehaviorSpace
Description:		Returns a list of the number of bacteria on each patch. Only works properly with a world with height of 1

**getNumBactLin**:
Function Type:	Reporter
Input:			x-coordinate
Output:		The number of bacteria on the patch at given x-coord
Purpose:		Used to help collect data in BehaviorSpace
Description:		Returns the number of bacteria on the patch at given x-coord. Only works properly with a world with height of 1.

**getNumSeeds**:
Function Type:	Reporter
Input:			None
Output:		The number of bacteria with isSeed set to true
Purpose:		Used to help collect data in BehaviorSpace
Description:		Returns the number of bacteria with isSeed set to true.

**getStuckChance**:
Function Type:	Reporter
Input:			x-coordinate
Output:		The stuckChance of the patch at the given x-coordinate.
Purpose:		Allows JUnit tests to check if the stuck chance is correct
Description:		Returns the stuckChance at patch (x 0). Works optimally with a world with a height of 1.

**getTrueAbs**:
Function Type:	Reporter
Input:			None
Output:		trueAbsorption
Purpose:		Allows JUnit tests to check if the trueAbsorption is correct.
Description:		Returns the trueAbsorption of the model. Is irrelevant when absorption is not incorporated.

**getResult**:
Function Type:	Reporter
Input:			None
Output:		result
Purpose:		Allows JUnit tests to retrieve any necessary, miscellaneous values from model.
Description:		Returns the result global variable. Necessary for JUnit testing.

**get-glucose**: 
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of glucose in a given patch before the movement of the metabolites began for that tick.

**get-lactate**: 
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of lactate in a given patch before the movement of the metabolites began for that tick.

**get-inulin**: 
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of inulin in a given patch before the movement of the metabolites began for that tick.

**get-lactose**: 
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of lactose in a given patch before the movement of the metabolites began for that tick.

**get-FO**: 
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of fructooligosaccharide in a given patch before the movement of the metabolites began for that tick.

**get-CS**:  
Function Type:	Reporter
Input:			x-coordinate and y-coordinate
Output:		amount of glucose in patch
Purpose:		helper function for make/store metabolites
Description:		helper reporter function that reports the amount of chondroitin sulfate in a given patch before the movement of the metabolites began for that tick.

**flowRateTest**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		help run the Flow Rate Tests
Description:		sets flowDist to specific values depending on the tick number.

**glucTest**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		help run the Glucose Tests
Description:		sets inFlowGlucose to specific values depending on the tick number.

**bifidosTest**:
Function Type:	Procedure
Input:			None
Output:		None
Purpose:		help run the Glucose Tests
Description:		sets inConcBifidos to specific values depending on the tick number.
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

bacteria
true
0
Circle -7500403 true true 103 28 95
Circle -7500403 true true 105 45 90
Circle -7500403 true true 105 60 90
Circle -7500403 true true 105 75 90
Circle -7500403 true true 105 90 90
Circle -7500403 true true 105 105 90
Circle -7500403 true true 105 120 90
Circle -7500403 true true 105 135 90
Circle -7500403 true true 105 150 90
Circle -7500403 true true 105 165 90
Circle -7500403 true true 105 180 90

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
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="checkStable" repetitions="4" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100[
  go
]</go>
    <timeLimit steps="50"/>
    <metric>testConst</metric>
    <metric>flowDist</metric>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="23562"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5490"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="921"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="27"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="flowTest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
flowRateTest</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="0.333"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="23562"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5490"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="921"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flowDist">
      <value value="0.278"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="glucTest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
glucTest</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="0.5"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="23562"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5490"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="921"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inFlowGlucose">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="bifidosTest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
bifidosTest</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="23562"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5490"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="921"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inConcBifidos">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="flowTestB" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
flowRateTest</go>
    <timeLimit steps="303"/>
    <metric>testConst</metric>
    <metric>flowDist</metric>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="0.333"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="22793"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5311"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="1842"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flowDist">
      <value value="0.278"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="glucTestB" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
glucTest</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="0.5"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="22793"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5311"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="1842"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inFlowGlucose">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="bifidosTestB" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]
bifidosTest</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="testConst">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="22793"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5311"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="1842"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inConcBifidos">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="controlHealthy" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="initNumClosts">
      <value value="921"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="23562"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5490"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="testConst">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="controlAutistic" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>repeat 100 [
  go
]</go>
    <timeLimit steps="303"/>
    <metric>count bifidos</metric>
    <metric>count bacteroides</metric>
    <metric>count closts</metric>
    <metric>count desulfos</metric>
    <metric>sum [inulin] of patches</metric>
    <metric>sum [lactate] of patches</metric>
    <metric>sum [lactose] of patches</metric>
    <metric>sum [FO] of patches</metric>
    <metric>sum [glucose] of patches</metric>
    <metric>sum [CS] of patches</metric>
    <metric>trueAbsorption</metric>
    <metric>getNumSeeds</metric>
    <metric>getAllBactPatchLin</metric>
    <enumeratedValueSet variable="initNumBifidos">
      <value value="22793"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumBacteroides">
      <value value="5311"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumClosts">
      <value value="1842"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initNumDesulfos">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="testConst">
      <value value="1"/>
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
0
@#$#@#$#@
