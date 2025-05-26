def format_numbers(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            formatted_line = '\t'.join(f"{int(num):02}" for num in line.split())
            outfile.write(formatted_line + '\n')

if __name__ == "__main__":
    format_numbers("newpuntata.txt", "newpuntata.txt.1")
    print("Formattazione completata! Il file 'newpuntata.txt' è stato generato.")

