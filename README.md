This is a script I quickly wrote for my own use. It's not well tested, nor well-maintained.

The script should convert Barclay's PDF statements to a tab-separated format. It's unlikely to work with other banks' statements.

## Usage

    pdftocsv.rb statement0.pdf [statement1.pdf ...]

TSV is output to STDOUT. If your shell supports expansion, the fastest way to export several statements to TSV is to put them in a `statements/` directory and run:

    pdftocsv.rb statements/* >statements.csv
