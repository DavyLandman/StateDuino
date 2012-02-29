module lang::StateDuino::ast::Main

data StateMachine = stateMachine(StateMachineIdentifier name, StartState startState, list[StateTransitions] transitions);

data StartState 
	= forkStart(ForkName fork)
	| actionStart(str action)
	;

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
	= action(str condition, StateTransitions transitions)
	;
	
	
data Coordinator = coordinator(str name, list[Invoke] invokes);

data Invoke = invoke(str name, list[ParameterValue] params);

data ParameterValue
	= normal(int number)
	| range(int startRange, int stopRange)
	;
	
anno loc StateMachine@location;
anno loc StartState@location;
anno loc StateMachineIdentifier@location;
anno loc Parameter@location;
anno loc StateTransitions@location;
anno loc StateTransition@location;
anno loc ForkName@location;
anno loc ForkConditionTransitions@location;
anno loc Coordinator@location;
anno loc Invoke@location;
anno loc ParameterValue@location;