module lang::StateDuino::semantics::Concepts

public set[str] validParameterTypes = 
	{
		"int", "uint", "bool", "pointer", "float",
		"uint8", "uint16", "uint32",
		"int8", "int16", "int32"
	};
	
public set[str] validForkConditions =
	{
		"yes", "no", "!"	
	};