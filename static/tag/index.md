---
layout: home
---

<div class="index-content opinion">

    <div class="section">

        <div class="cate-bar"><span id="cateBar"></span></div>

        <ul class="artical-list">
        {% for tag in site.tags %}
            <li>
             	<h2 id="{{tag[0]}}">
	                <a href="/tag#{{tag[0]}}" title="View all posts filed under {{tag|first}}">{{tag[0]}}</a>
	            </h2>
	             	{% assign pages_list = tag[1] %}
            			{% for post in pages_list %}
                   <div class="title-desc">
                          <a href="{{ post.url }}">{{post.title}}</a> {{ post.date|date:"%Y-%m-%d"}}</div>
        				{% endfor %}
            </li>
        {% endfor %}
        </ul>
    </div>
    <div class="aside">
    </div>
    <div class="aside">
		{% include aside_taglist.html %}
    </div>
</div>
