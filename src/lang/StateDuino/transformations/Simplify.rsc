module lang::StateDuino::transformations::Simplify

import List;
import Map;
import IO;
import Relation;
import Set;
import lang::StateDuino::ast::Main;

public StateMachine simplify(StateMachine complex) {
	StateMachine result = complex;
	result = removeUnnamedForks(result);
	result = inlineChains(result);
	//result = unnestForks(result);
	//result = removeMainActions(result);
	return result;
}
private StateMachine removeUnnamedForks(StateMachine sm) {
	int newNameCounter = 0;
	return visit(sm) {
		case f:namelessFork(types, pre, paths) : {
			Name newName = name("_nameless<newNameCounter>")[@location = f@location];
			newNameCounter += 1;
			insert fork(types, newName , pre, paths)[@location = f@location];
		}
	};
}

private StateMachine inlineChains(StateMachine complex) {
// not correct for a chain referencing another chain!
	map[str, list[Action]] chainActions = ( m : p | chain(name(m), p) <- complex.definitions);
	Definition replaceActions(Definition def, set[str] nestedForkNames) {
		list[ConditionalPath] newPaths = [];
		for (p <- def.paths) {
			list[Action] newActions= [];
			for (a <- p.actions) {
				switch(a) {
					case action(nm): 
						if (!(nm in nestedForkNames) && chainActions[nm]?) {
							newActions += chainActions[nm];	
						}	
						else {
							newActions += [a];	
						}
					case d:definition(f) : {
						newActions += [d[definition = replaceActions(f, nestedForkNames + (f.name? ? {f.name.name} : {}))]];	
					}
				}
			}
			newPaths += [p[actions = newActions]];
		}
		return def[paths= newPaths];
	};	
	list[Definition] newDefinitions = [replaceActions(f, {}) | f:fork(_,_,_,_) <- complex.definitions];
	return complex[definitions = newDefinitions];
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