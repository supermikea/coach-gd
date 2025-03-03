#!/usr/bin/env python3
import sys
import json
import matplotlib.pyplot as plt

def main():
    if len(sys.argv) < 4:
        print("Usage: {} <json_file> <x_key> <y_key>".format(sys.argv[0]))
        sys.exit(2)
    
    json_file = sys.argv[1]
    x_key = sys.argv[2]
    y_key = sys.argv[3]

    try:
        with open(json_file, "r") as file:
            data = json.load(file)
    except Exception as e:
        print("Error reading JSON file:", e)
        sys.exit(2)

    # Extract x and y values
    x_vals = [entry.get(x_key, 0) for entry in data]
    y_vals = [entry.get(y_key, 0) for entry in data]

    plt.figure()
    plt.plot(x_vals, y_vals, marker='o')
    plt.xlabel(x_key)
    plt.ylabel(y_key)
    plt.title(f"Plot of {y_key} vs {x_key}")
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
