module lang::StateDuino::transformations::Simplify

import List;
import IO;
import lang::StateDuino::ast::Main;

public StateMachine simplify(StateMachine complex) {
	return nestActions(complex);
}

private StateMachine nestActions(StateMachine complex) {
	map[str, StateTransitions] globalActions = ();
	for (c:chain([action(firstName), rest:_*]) <- complex.transitions) {
		if (chain([before:_*, forkDescription(forkName,_)]) := c) {
			// remove the fork description for this chain to avoid nested fork descriptions
			oldC = c;
			c = chain([before, fork(forkName)]);
			c@location = oldC@location;
		}
		globalActions[firstName] = c;		
	}
	
	StateMachine nested = visit(complex) {
		case action(name, c:chain([_*,action(actionName)])) =>
			action(name, chain(prefix(c.transitions) + (globalActions[actionName].transitions)))
	};
	return nested;
}

private StateMachine unnestForks(StateMachine nestedActions) {


}