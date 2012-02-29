module lang::StateDuino::ast::Load

import lang::StateDuino::cst::Parse;
import lang::StateDuino::ast::Main;
import ParseTree;

public StateMachine getStateMachine (str stateMachineString) 
	= implode(#StateMachine, parseStateMachine(stateMachineString));

public StateMachine getStateMachine (loc stateMachineFile) 
	= implode(#StateMachine, parseStateMachine(stateMachineFile));

public StateMachine getStateMachine (Tree stateMachineParsedTree) 
	= implode(#StateMachine, stateMachineParsedTree);
	
public Coordinator getCoordinator (str stateMachineString) 
	= implode(#Coordinator, parseCoordinator(stateMachineString));

public Coordinator getCoordinator (loc stateMachineFile) 
	= implode(#Coordinator, parseCoordinator(stateMachineFile));

public Coordinator getCoordinator (Tree coordinatorParsedTree) 
	= implode(#Coordinator, coordinatorParsedTree);