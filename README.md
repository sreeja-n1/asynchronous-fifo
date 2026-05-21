# asynchronous-fifo
What is an Asynchronous FIFO?
A FIFO (First In First Out) is a buffer — data goes in one end and comes out the other in the same order, like a queue at a coffee shop.
An asynchronous FIFO takes this further. It lets two circuits running at different clock speeds share data safely. One side writes data fast, the other reads it slow (or vice versa), and the FIFO handles the mismatch without losing or corrupting anything.
Without it, directly connecting two circuits on different clocks causes metastability — a state where a signal gets stuck between 0 and 1, causing unpredictable behavior and system crashes.
![Async FIFO Block Diagram](async-fifo.png)
