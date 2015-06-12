/* Template code */
import java.io.*;
public class Main {
    public static void main (String[] args) throws IOException {
        File file = new File(args[0]);
        BufferedReader buffer = new BufferedReader(new FileReader(file));
        String line;
        while ((line = buffer.readLine()) != null) {
            line = line.trim();
            // Process line of input Here
        }
    }
}

/*
 * The MaxStack is a stacklike data structure that also allows stacklike access to the elements by their value
 * For example, given a stack of {1, 3, 2, 5, 3, 4, 5, 2}
 * peek() -> 2, peekMax() -> 5
 * pop() -> 2; peek() -> 5, peekMax() -> 5
 * pop() -> 5; peek() -> 4, peekMax() -> 5
 * push(6); peek() -> 6, peekMax() -> 6
 * popMax() -> 6; peek -> 4, peekMax() -> 5
 * popMax() -> 5; peek -> 4, peekMax() -> 4
 */
public interface MaxStack<T extends Comparable<T>> {

    // The standard three Stack methods - push adds an element to the stack
    public void push(T toPush);
    // Peek returns the top value on the stack
    public T peek();
    // Pop removes and returns the top value on the stack
    public T pop();
     
    // Two special methods, so this isn't just 'implement a stack'
    // PeekMax() returns the highest value in the stack (remember that T must implement Comparable)
    public T peekMax();
    // popMax() removes and returns the highest value in the stack
    public T popMax();
}