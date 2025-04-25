# Holiday Time Hacker

### Purpose

**Holiday Time Hacker** is a smart holiday planning tool designed to help you maximize your paid time off (PTO) by automatically identifying the best days to take off around public holidays and weekends. Using intelligent calendar analysis, it helps turn a few PTO days into extended breaks, saving you time and effort while planning your vacations.

---

### Features

- **Country-Specific PTO**: Automatically fetches holiday data based on the country selected (currently supports multiple countries with their respective PTO regulations).
- **Smart PTO Optimization**: Finds optimal days to take off around weekends and public holidays to extend your breaks.
- **Interactive Calendar**: A visually interactive calendar where you can toggle days off, use suggested PTO, or manually select dates.
- **Editable PTO Days**: Customize the number of PTO days available based on your country's regulations or your personal preferences.

---

### Installation
#### Without Docker:
1. **Clone the Repository**:

```bash
git clone https://github.com/rafaelfalcao/holiday-time-hacker.git
cd holiday-time-hacker
   
1. **Install Dependencies**:

   **Make sure you have [Node.js](https://nodejs.org/) installed.** 
```
apt install npm
```
Then, run the following command to install the necessary dependencies:
```
npm install 
```
   
2. **Run the Project**:

	After installing the dependencies, run the following command to start the development server:
```
npm run dev
```
The app should now be accessible in your browser at `http://localhost:3000`.

#### With Docker:

1.  **Build the Docker Image**:
```
docker build -t holiday-time-hacker .
```
2. **Run the Docker Container**:
```
docker run -p 3000:3000 holiday-time-hacker
```

----------
### Usage

Once the app is running, you can follow these steps to plan your holidays:

1.  **Select Your Country**: From the dropdown, select the country you're located in to automatically load public holidays and the corresponding PTO days.
    
2.  **Adjust PTO Days**: If you have more PTO days than the default, you can manually adjust the number of days using the input field. This will update the suggested PTO.
    
3.  **View the Calendar**: The calendar will show each month, with weekends and public holidays highlighted. You can click on any day to toggle it as a PTO day.
    
4.  **Use Suggested PTO**: Click the "Edit Suggested PTO" button to automatically select optimal days off based on the weekends and public holidays. You can choose to keep or remove the suggested days.
    
5.  **Track Total Days Off**: As you select your PTO days, the total number of days off (including weekends and public holidays) will be updated.

### License

This project is **not for distribution or usage** outside personal use. You may not use, copy, modify, or distribute this software without permission.

**License**: No Usage or Distribution License

----------

### Contributing

Feel free to fork the repository and submit pull requests. If you have any improvements or bug fixes, please create an issue or contribute directly.

----------

### Contact

-   **Author**: Rafael Falcão 🦅
    
-   **GitHub**: [rafaelfalcao](https://github.com/rafaelfalcao)
    
-   **Powered by**: ChatGPT-4o

----------

### Acknowledgments

- **SvelteKit**: A modern framework for building fast, lightweight apps.
- **Date-Holidays**: Used for fetching public holiday data.
- **Docker**: For containerizing and running the app.
- **ChatGPT-4o**: For assisting in the development of this tool.