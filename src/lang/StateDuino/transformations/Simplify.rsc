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
		if (chain([before:_*, forkDescription(forkName,_)]) := c) {
			// remove the fork description for this chain to avoid nested fork descriptions
			c = chain([before, fork(forkName)]);
		}
		globalActions[firstName] = c;		
	}
	StateMachine nested = complex;
	solve(nested) {
		nested = visit(nested) {
			case c:chain([_*,action(actionName)]) =>
				chain(prefix(c.transitions) + (globalActions[actionName].transitions))
		};
	}
	return nested;
}

private StateMachine unnestForks(StateMachine nestedActions) {
	set[str] forksSeen = {forkName.name | chain([forkDescription(forkName, _)]) <- nestedActions.transitions};
	
	StateTransition processForkDefinition(f:forkDescription(forkName, acts)) {
			str newForkName = forkName.name;
			while (newForkName in forksSeen) {
				// we have to rename this fork because a name collision exists
				newForkName += "?";
			}	
			forksSeen += {newForkName};
			if (forkName.name != newForkName) {
				str oldName = forkName.name;
				// now shadow the usage of this forkname
				return visit(f[name = forkName[name = newForkName]]) {
					case normalFork(oldName) => normalFork(newForkName)
					case sleepableFork(oldName) => sleepableFork(newForkName)
					case nonBlockingFork(oldName) => nonBlockingFork(newForkName)
				};	
			}
			return f;
	}
	
	set[StateTransitions] newGlobalTransitions = {};
	renamedForks = visit(nestedActions) {
		case c:chain([notfork, _*, f:forkDescription(forkName, _)]) : {
			StateTransition newGlobal =processForkDefinition(f);
			newGlobalTransitions += {chain([newGlobal])};
			insert c[transitions = prefix(c.transitions) + [fork(newGlobal.name)]];
		}
		case a:action(_, c:chain([ _*, f:forkDescription(forkName, _)])) : {
			StateTransition newGlobal =processForkDefinition(f);
			newGlobalTransitions += {chain([newGlobal])};
			insert a[transitions = c[transitions = prefix(c.transitions) + [fork(newGlobal.name)]]];
		}
	};
	// now append the unnested forks
	return renamedForks[transitions = renamedForks.transitions + toList(newGlobalTransitions)];
	
	
	/*
	map[str, StateTransition] globalForks = (fName.name : f | chain([f:forkDescription(fName,_)]) <- nestedActions.transitions);
	list[StateTransition] allForks = [f | /chain([_*, f:forkDescription(_,_)]) <- nestedActions.transitions];
	rel[StateTransition old, StateTransition new] nestedToUnnested = {};
	
	println("waht <size(allForks)>");
	iprint(allForks);
	for (currentFork:forkDescription(forkName,_) <- allForks, !(currentFork in range(globalForks))) {
		println("checkingFork <forkName.name>");
		str newForkName = forkName.name;
		while (globalForks[newForkName]?) {
			// we have to rename this fork because a name collision exists
			newForkName += "?";
		}	
		println("newName <newForkName>");
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
	*/
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