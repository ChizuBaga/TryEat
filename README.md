<p align="center">
	<img width="250" height="250" class="center" alt="6850f91264af49f7b220006dd733e537" src="https://github.com/user-attachments/assets/6b918f54-46e2-4238-b57f-57a3a376b9e2" />
</p>

# TryEat -- "吃看看"

> [!NOTE]
> A mobile application project during the UMPSA Hackathon 2025. *(TryIt - TryEat, get it? hahaha...yea nvm)*
> 
> *Code is a mess despite the attempt to follow MVC architecture, and few modules are shamlessly vibe-coded*🤡


<br>


## Description 📟
*What is this application about, who is it for, and why?*

### Who is it for?
For home-based micro sellers, working in the Food & Beverage Service Sector.

### Why?
Sellers uses different digital platforms for different purposes such as posting/advertising, communication, payment, sales tracking and do not appear in established delivery platforms due to the absence of business registration. This results in a limited market visibility, constrained by the *organic exposure* on social media *(unless paid)*, affecting their opportunity for deserved growth.

### The "what"?
To provide a **centralized** digital platform and a digital storefront for **Micro** home-based F&B sellers.
Functions included for sellers are:
- Real-time chat for inquiry
- Dashboard module to view sales information
- Catalogue module to add/delete/edit items for sell
- Instant order & delivery, OR Pre-order function
- Accepting/Reject orders

Functions for customers are:
- Real-time chat for inquiry
- Browse sellers catalogue
- Recommends nearby sellers within the range of 50KM + Map visualisation
- Cart & Ordering system
- *Fake* Payment system
- Good/Bad indicators based on comments using Naive Bayes
- Summary of comments using Gemini

---

# Technologies used 🤖
1. HMS Kits:
	- Location kit (FusedLocationProvider)
	- Site kit (Forward Geocoding)
	- Map kit
	- Push kit for notification *(fragile)*
2. Artificial Intelligence:
	- Multinomial NB - Sentiment analysis for comments
	- Gemini LLM - Comments summarisation
3. Programming Languages
	- Dart + Flutter framework
	- Python

