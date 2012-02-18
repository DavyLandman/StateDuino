module lang::StateDuino::ast::Main

data StateMachine = stateMachine(StateMachineIdentifier name, list[StateTransitions] transitions);

data StateMachineIdentifier 
	= normal(str name)
	| parameterized(str name, list[Parameter] params)
	;

data Parameter = param(str \type, str name);

data StateTransitions = chain(list[StateTransition] transitions);

data StateTransition 
	= action(str action)
	| fork(ForkName name)
	| forkDescription(ForkName name, list[ForkConditionTransitions] transitions)
	;

data ForkName
	= normalFork(str name)
	| sleepableFork(str name)
	| nonBlockingFork(str name)
	;
	
data ForkConditionTransitions
	= action(ForkCondition condition, StateTransitions transitions)
	;
	
data ForkCondition = yes() | no() | always();

anno loc StateMachine@location;
anno loc StateMachineIdentifier@location;
anno loc Parameter@location;
anno loc StateTransition@location;
anno loc ForkName@location;
anno loc ForkConditionTransitions@location;
anno loc ForkCondition@location;