import re
import requests
import csv
from bs4 import BeautifulSoup
import unicodedata


BASE_URL = "https://physics.nist.gov/cgi-bin/XrayTrans/search.pl"
NUM_RE = re.compile(r'(\d[\d\s]*\.\d+|\d[\d\s]*)')  # will match "817.69" from "817.69(56) and ignore spaces"

def fetch_element_data(element_symbol):
    params = {"element": element_symbol, "lower": "", "upper": "", "units": "eV"}
    r = requests.get(BASE_URL, params=params, timeout=10)
    r.raise_for_status()
    return r.text

def parse_transitions(html_text, element_symbol):
    """
    Parse the NIST XrayTrans HTML table for transitions.
    Returns list of [element_symbol, transition, theoretical_eV, experimental_eV]
    """
    soup = BeautifulSoup(html_text, "lxml")

    rows_out = []
    # find the main table that contains the transition rows
    # usually the first <table> after the header block holds the data; robust fallback: search all <tr>
    tr_list = soup.find_all("tr")
    for tr in tr_list:
        tds = tr.find_all("td")
        if not tds:
            continue
        # find the first td that looks like a transition name (contains letters and/or 'edge')
        # and at least one subsequent td that could contain numeric energy
        # Use text from td[0] if it contains letters; otherwise try to locate a td with a transition-like string
        transition_td = None
        # Common layout: td[0] = transition name, td[1] = theoretical, td[2] = experimental (or similar)
        # But there are many empty filler cells so we scan left-to-right for first td with an alphabetic char
        for td in tds:
            txt = td.get_text(strip=True)
            if txt and re.search(r'[A-Za-z]', txt):
                # exclude header refs like "Ref." by ignoring rows where text length is very short and contains only non-transition words
                # Accept if contains letters and at most a few characters or contains 'K','L','M','edge'
                if re.search(r'K|L|M|edge|KL|KM|LK|LM', txt, re.IGNORECASE):
                    transition_td = td
                    break
                # fallback: if text looks like e.g. "KL1" or "K edge" accept
                transition_td = td
                break
        if transition_td is None:
            continue

        transition_name = transition_td.get_text(" ", strip=True)  # preserves subscript numbers e.g. "KL1" or "K edge"
        # Now search subsequent tds (those to the right of transition_td) for numeric energies
        # find index of transition_td in tds
        try:
            start_idx = tds.index(transition_td)
        except ValueError:
            start_idx = 0

        theoretical = ""
        experimental = ""
        for td in tds[start_idx + 1:]:
            txt = td.get_text(" ", strip=True)
            if not txt:
                continue
            # find the first numeric token (this will grab "817.69" from "817.69(56)")
            m = NUM_RE.search(txt)
            if m:
                val = m.group(1).replace(" ", "")  # remove spaces in "54 074.8"
                if not theoretical:
                    theoretical = val
                elif not experimental:
                    experimental = val
                    break  # got both values, done for this row

        # Keep only rows where we found at least the theoretical energy
        if theoretical:
            rows_out.append([element_symbol, transition_name, theoretical, experimental])

    return rows_out

def clean_num(x):
    if not x:
        return ''
    # normalize Unicode (remove Â, non-breaking spaces, narrow spaces)
    x = unicodedata.normalize('NFKC', x)
    x = x.replace('\u00A0', '').replace('\u202F', '').replace(' ', '')
    # enforce dot as decimal separator
    x = x.replace(',', '.')
    return x

def main():
    elements = [
        "Ne","Na","Mg","Al","Si","P","S","Cl","K","Ca","Ti","V","Cr","Mn","Fe",
        "Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr","Rb","Sr","Y","Zr",
        "Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In","Sn","Sb","Te","I","Xe",
        "Cs","Ba","La","Ce","Pr","Nd","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm",
        "Yb","Lu","Hf","Ta","W","Re","Os","Ir","Pt","Au","Hg","Tl","Pb","Bi",
        "Th","U"
    ]

    out_fname = "nist_xray_transitions_test.csv"
    with open(out_fname, "w", newline="", encoding="utf-8") as f:
        # use quoting to avoid problems with commas in text fields
        w = csv.writer(f, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        w.writerow(["Element", "Transition", "Theoretical_eV", "Experimental_eV"])
        for el in elements:
            print(f"Fetching {el}")
            html = fetch_element_data(el)
            data = parse_transitions(html, el)
            for row in data:
                # replace commas in transition names and ensure decimal points
             row[1] = row[1].replace(',', ' ')   # prevent commas inside text
             row[2] = clean_num(row[2])
             row[3] = clean_num(row[3])
             w.writerow(row)

    print("Saved", out_fname)


if __name__ == "__main__":
    main()
