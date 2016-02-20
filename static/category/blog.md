---
layout: home
---

<div class="index-content blog">
    <div class="section">
        <ul class="artical-cate">
            <li class="on"><a href="/"><span>Blog</span></a></li>
            <li style="text-align:center"><a href="/category/opinion.html"><span>Opinion</span></a></li>
            <li style="text-align:right"><a href="/category/project.html"><span>Project</span></a></li>
        </ul>

        <div class="cate-bar"><span id="cateBar"></span></div>

        <ul class="artical-list">
        {% for post in site.categories.blog %}
            <li>
                <span style="float:right">
                {{ post.date|date:"%Y-%m-%d"}}
                </span>
                <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
                <div class="title-desc">                
                Tags : {% for tag in post.tags %}                
                	<a href="/tag#{{tag}}" title="View all posts filed under {{tag}}">{{tag}}</a>
                {% endfor %}
                </div>
                <div class="title-desc">                   
                {{ post.description }}
                </div>
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
