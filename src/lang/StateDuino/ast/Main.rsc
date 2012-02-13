module lang::StateDuino::ast::Main

data StateMachine = stateMachine(StateMachineIdentifier name, list[StateTransition] transitions);

data StateMachineIdentifier 
	= normal(str name)
	| parameterized(str name, list[Parameter] params)
	;

data Parameter = param(str \type, str name);
//data Type = \int() | \bool();

data StateTransition 
	= singleAction(str action)
	| singleFork(str name)
	| actionChain(str from, StateTransition to)
	| forkDescription(str name, list[ForkConditionTransitions] transitions)
	;
	
data ForkConditionTransitions
	= action(ForkCondition condition, StateTransition transitions)
	| sleepableLoop(ForkCondition condition)
	;
	
data ForkCondition = yes() | no() | always();