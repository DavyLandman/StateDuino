module lang::StateDuino::transformations::Simplify

import List;
import Map;
import IO;
import Relation;
import Set;
import lang::StateDuino::ast::Main;

public StateMachine simplify(StateMachine complex) {
	StateMachine result = complex;
	result = nestActions(result);
	result = unnestForks(result);
	result = removeMainActions(result);
	return result;
}

private StateMachine nestActions(StateMachine complex) {
	map[str, StateTransitions] globalActions = ();
	for (c:chain([action(firstName), rest:_*]) <- complex.transitions) {
		if (chain([before:_*, forkDescription(forkName,_)]) := c, !(nonBlockingFork(_) := forkName)) {
			// remove the fork description for this chain to avoid nested fork descriptions
			c = chain([before, fork(forkName)]);
		}
		globalActions[firstName] = c;		
	}
	for (c:chain([f:forkDescription(nonBlockingFork(forkName), _)]) <- complex.transitions) {
		globalActions[forkName] = c;		
	}
	StateMachine nested = complex;
	solve(nested) {
		nested = visit(nested) {
			case c:chain([_*,action(actionName)]) =>
				chain(prefix(c.transitions) + (globalActions[actionName].transitions))
			case c:chain([_*,fork(nonBlockingFork(forkName))]) =>
				chain(prefix(c.transitions) + (globalActions[forkName].transitions))
		};
	}
	return nested;
}

private StateMachine unnestForks(StateMachine nestedActions) {
	map[str, StateTransition] globalForks = (fName.name : f | chain([f:forkDescription(fName,_)]) <- nestedActions.transitions);
	set[StateTransition] allForks = {f | /chain([_*, f:forkDescription(_,_)]) <- nestedActions.transitions};
	rel[StateTransition old, StateTransition new] nestedToUnnested = {};
	
	for (currentFork:forkDescription(forkName,_) <- allForks, !(currentFork in range(globalForks))) {
		str newForkName = forkName.name;
		while (globalForks[newForkName]?) {
			// we have to rename this fork because a name collision exists
			newForkName += "?";
		}	
		newFork = currentFork[name = forkName[name = newForkName]];
		nestedToUnnested += {<currentFork, newFork>};
		globalForks[newForkName] = newFork;
	}	
	
	list[StateTransitions] newGlobalTransitions = [ chain([f]) | f <- domain(nestedToUnnested)];
	// get the names of unnested forks
	set[str] newUnnestedForks = {f.name.name | chain([f]) <- newGlobalTransitions};
	
	StateMachine unnested = nestedActions[transitions = nestedActions.transitions + newGlobalTransitions];
	return visit(unnested) {
		case f:forkDesciption(name, _) => fork(nestedToUnnested[f].name) 
			when name in newUnnestedForks
	};
}
private StateMachine removeMainActions(StateMachine simplified) {
	str startState = (simplified.startState.action?) ? simplified.startState.action : simplified.startState.fork.name;
	list[StateTransitions] newTransitions = [];
	for (c:chain([first,_*]) <- simplified.transitions)  {
		if (action(name) := first) {
			if (name == startState) {
				newTransitions += [c];	
			}
		}
		else {
			newTransitions += [c];	
		}
	};
	return simplified[transitions = newTransitions];
}