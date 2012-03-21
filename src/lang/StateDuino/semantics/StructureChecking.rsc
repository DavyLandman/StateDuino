module lang::StateDuino::semantics::StructureChecking

import Map;
import List;
import Set;
import Message;
import Relation;
import Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;


private set[Message] structureCheck(StateMachine sm) = checkForAlreadyDefinedNames(sm);


private set[Message] checkForAlreadyDefinedNames(StateMachine sm) {
	set[Message] result = {};
	set[Name] alreadyDefined = {};
	for (d <- sm.definitions, d.name?) {
		if (d.name in alreadyDefined) {
			result += {error("<d.name.name> is already defined", d.name@location)};
		}
		alreadyDefined += {d.name};
	}
	return result;
}