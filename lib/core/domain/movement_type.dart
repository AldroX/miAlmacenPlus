/// Direction of a stock movement: a movement either adds stock (incoming)
/// or removes stock (outgoing). Stock only changes through movements of
/// either direction (spec requirement 2.1).
enum MovementType { incoming, outgoing }
