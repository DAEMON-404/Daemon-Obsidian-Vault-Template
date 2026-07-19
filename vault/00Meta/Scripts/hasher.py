#!/usr/bin/env python3
import os
import hashlib
import argparse
from pathlib import Path
from datetime import datetime

# Configuration
HASH_STORE_DIR = Path("00Meta/Hashes")

def calculate_file_hashes(file_path, algorithms=['md5', 'sha256']):
    """Calculates hashes for a single file."""
    hashes = {}
    try:
        # Initialize hash objects
        hash_objs = {algo: hashlib.new(algo) for algo in algorithms}
        
        # Read file in chunks to save memory
        with open(file_path, "rb") as f:
            while chunk := f.read(8192):
                for h in hash_objs.values():
                    h.update(chunk)
                    
        for algo, h in hash_objs.items():
            hashes[algo] = h.hexdigest()
            
        return hashes
    except Exception as e:
        return {"error": str(e)}

def format_output_header(target_path, algorithms):
    """Creates a header for the hash file with metadata."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header = [
        "=" * 60,
        f"HASH REPORT",
        "=" * 60,
        f"Target:       {target_path.resolve()}",
        f"Date/Time:    {timestamp}",
        f"Algorithms:   {', '.join(upper_algos(algorithms))}",
        "=" * 60,
        ""
    ]
    return "\n".join(header)

def upper_algos(algos):
    return [a.upper() for a in algos]

def process_directory(directory, algorithms):
    """Recursively hashes all files in a directory and returns list of result strings."""
    results = []
    
    print(f"[*] Scanning directory: {directory}")
    
    for root, dirs, files in os.walk(directory):
        # Sort for consistent output
        files.sort()
        dirs.sort()
        
        for file in files:
            if file.startswith('.'): continue
            
            file_path = Path(root) / file
            hashes = calculate_file_hashes(file_path, algorithms)
            
            if "error" in hashes:
                err_msg = f"[!] Error processing {file}: {hashes['error']}"
                print(err_msg)
                results.append(err_msg)
                continue
                
            # Format result
            res_str = f"File: {file_path}\n"
            for algo, val in hashes.items():
                res_str += f"  {algo.upper()}: {val}\n"
            
            results.append(res_str)
            # Optional: Print to console as we go (brief version)
            print(f"  + Hashed: {file}")

    return results

def main():
    parser = argparse.ArgumentParser(description="Advanced File & Directory Hasher with Auto-Archiving")
    parser.add_argument("path", help="File or directory path to hash")
    parser.add_argument("-a", "--algos", nargs="+", default=["md5", "sha256"], 
                        help="Hash algorithms to use (md5, sha1, sha256, sha512, etc.)")
    
    args = parser.parse_args()
    target_path = Path(args.path)
    
    if not target_path.exists():
        print(f"[!] Error: Path '{target_path}' does not exist.")
        return

    # 1. Setup Output Directory Structure
    # Structure: 00Meta/Hashes/<TargetName>/
    target_name = target_path.name
    output_dir = HASH_STORE_DIR / target_name
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 2. Setup Output Filename
    # Name: <TargetName>_<YYYYMMDD_HHMMSS>.txt
    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_filename = f"{target_name}_{timestamp_str}.txt"
    output_file_path = output_dir / output_filename
    
    print(f"[*] Starting hash job for: {target_name}")
    print(f"[*] Output will be saved to: {output_file_path}")
    
    # 3. Generate Content
    report_content = []
    report_content.append(format_output_header(target_path, args.algos))
    
    if target_path.is_file():
        hashes = calculate_file_hashes(target_path, args.algos)
        res_str = f"File: {target_path.name}\n"
        for algo, val in hashes.items():
            res_str += f"  {algo.upper()}: {val}\n"
        report_content.append(res_str)
        print(f"  + Hash calculated for {target_path.name}")
            
    elif target_path.is_dir():
        dir_results = process_directory(target_path, args.algos)
        report_content.extend(dir_results)

    # 4. Write to File
    try:
        with open(output_file_path, "w") as f:
            f.write("\n".join(report_content))
        print(f"[*] Success! Report generated at: {output_file_path}")
    except Exception as e:
        print(f"[!] Error writing report: {e}")

if __name__ == "__main__":
    main()
