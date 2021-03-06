# $Id: post_helper.rb 311 2007-02-06 15:28:51Z garrett $

#--
# Copyright (C) 2006-2007 Garrett Murray
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program (doc/LICENSE); if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301 USA.
#++

module PostHelper
  
  # build a linked-list of tags for a post
  def build_tag_list(tags, archive_token = get_pref('ARCHIVE_TOKEN'), separator = ', ')
    url = Preference.get_setting('domain')
    url = (url != '' ? 'http://' + url : '')
    list = ''
    for tag in tags
      list += (list != '' ? separator : '') + "<a href=\"#{url}/#{archive_token}/tags/#{tag}\" class=\"tag public_tag\" title=\"View posts tagged with &quot;#{tag}&quot;\">#{tag}</a>"
    end
    return list
  rescue
  # in case something goes wrong...
    return ''
  end

  # build links to previous and next post when viewing an individual post archive, pass
  # true for show_titles and you'll get those instead of just previous and next
  # set append_left and append_right to add things like arrows to the links
  def previous_next(current_post, div = 'item_hierarchy', title = 'Hierarchy: ', show_titles = false, prev_text = 'previous', next_text = 'next', append_left = '', append_right = '', separator = ', ')
    links = ''
    # run the queries
    @previous = Post.find_previous(current_post)
    @next = Post.find_next(current_post)
    if @previous.length > 0 or @next.length > 0
    # we've got something either before or after us
      # start building the links
      links += (div != '' ? '<div class="' + div + '">' : '') + title
      for post in @previous
        # grab the previous link if we've got one
        links += (append_left != '' ? append_left + ' ' : '') + link_to((show_titles ? post.title : prev_text), Post.permalink(post), :title => 'Previous post')
      end
      for post in @next
        # grab the next link if we've got one
        # if there was a previous link, we should add a space and such first
        links += (@previous.length > 0 ? separator : '') + link_to((show_titles ? post.title : next_text), Post.permalink(post), :title => 'Next post') + (append_right != '' ? ' ' + append_right : '')
      end
      # all done!
      return links + (div != '' ? '</div>' : '')
    else
    # no previous or next links
      return ''
    end
  rescue
  # whoops!
    return ''
  end
  
  # use this in views to get any posts you want (say, for instance, all posts with comments)
  # uses SQL so people can do virtually anything they want with it
  #### DEPRECATED: Site site_helper -> get_posts
  def get_posts(sql = "select * from posts where is_active = 1 order by created_at desc")
    logger.warn('DEPRECATED: The PostHelper method get_posts() has been deprecated. Please use Site.get_posts() instead.')
    return Post.find_flexible(sql)
  end
  
  # date/time of post linked, using formats from preferences
  def date_time_linked(post, separator = "at")
    return "<a href=\"#{Post.permalink(post)}\" title=\"Permalink for this post\">#{post.created_at.strftime(Preference.get_setting('date_format'))} #{separator} #{post.created_at.strftime(Preference.get_setting('time_format'))}</a>"
  end
  
  # date/time of post
  def date_time(post, hide_time = false)
    return post.created_at.strftime(Preference.get_setting('date_format')) + (hide_time ? '' : " at #{post.created_at.strftime(Preference.get_setting('time_format'))}")
  end
  
  # create post excerpt for search results
  def post_excerpt(post)
    return truncate_words(Post.strip_html(post.body), 20)
  end
  
  # same as above, but for comments
  def date_time_comment_linked(comment, post)
    return "<a href=\"#{Post.permalink(post)}\#c#{comment.id.to_s}\" title=\"Permalink for this comment\">#{comment.created_at.strftime(Preference.get_setting('date_format'))} at #{comment.created_at.strftime(Preference.get_setting('time_format'))}</a>"
  end
  
  #TODO: globalize it
  def date_time_comment_fr(comment, post)
    "#{comment.created_at.strftime(Preference.get_setting('date_format'))} - #{comment.created_at.strftime(Preference.get_setting('time_format'))}"
  end
  
  # if there's extended content, this shows a link
  def extended_content_link(post, wrap_in_p = true)
    if post.extended != ''
      ext_link = Preference.get_setting('extended_link_text')
      ext_link = "<a href=\"#{Post.permalink(post)}\" title=\"#{ext_link}\">#{ext_link}</a>"
      return (wrap_in_p ? '<p>' : '') + ext_link + (wrap_in_p ? '</p>' : '')
    else
      return ''
    end
  end
  
  # if there's extended content, this shows it
  def extended_content_block(post)
    return (post.extended != '' ? post.extended : '')
  end
  
  # if the comment system is turned on, return comment info for a post
  def comment_info(post)
    if post.comment_status != 0
      return "<a href=\"#{Post.permalink(post)}\#comments\" title=\"Comments for this post\">#{post.comments.length.to_s}#{(post.comment_status == 2 ? ' (comments closed)' : ' (view/add your own)')}</a>"
    else
      return '(disabled)'
    end
  end
  
  #TODO: globalize it
  def comment_info_fr(post)
    if post.comment_status != 0
      return "<a href=\"#{Post.permalink(post)}\#comments\" title=\"Commentaire sur cet article\">#{post.comments.length.to_s}#{(post.comment_status == 2 ? ' (commentaires fermés)' : ' commentaire'+(post.comments.count >= 2 ? 's' : ''))}</a>"
    else
      return '(désactivés)'
    end
  end

  # describes the current comment amount for a post in language
  def comment_count_description(post)
    if post
      return "There #{(post.comments.length == 1 ? 'is' : 'are')} #{pluralize(post.comments.length, 'comment')} on this post."
    else
      return ''
    end
  end
 
  #TODO: globalize or i18n it...
  def comment_count_description_fr(post)
    if post
      return "Il y a #{pluralize(post.comments.length, 'commentaire')} sur cet article."
    else
      return ''
    end
  end 

  # a link to posting, if posting comments is allowed for this post
  def add_comment_link(post)
    if post.comment_status == 1
      return '&nbsp;<a href="#post" title="Post yours &rarr;">Post yours &rarr;</a>'
    else
      return ''
    end
  end
  
  #TODO: i18n it..
  def add_comment_link_fr(post)
    if post.comment_status == 1
      return '&nbsp;<a href="#post" title="En ajouter un &rarr;">En ajouter un &rarr;</a>'
    else
      return ''
    end
  end

  # return the commenter's name, linked if necessary
  def comment_author(comment)
    if comment.url and comment.url != ''
      return "<a href=\"#{comment.url}\" title=\"View #{comment.name}'s website\">#{comment.name}</a>"
    else
      return comment.name
    end
  end
  
  # boolean... does this post accept comments?
  def accepting_comments(post)
    return (post.comment_status == 1 ? true : false)
  end
  
  # if there are tags, return them for this post
  def tag_info(post, separator = ", ")
    if post.tags.length > 0
      return build_tag_list(post.tags.map(&:name).sort!, get_pref('ARCHIVE_TOKEN'), separator)
    else
      return '(none)'
    end
  end
  
  # if we are showing authors, return them for this post
  def author_info(post, prefix = 'by ', archive_token = get_pref('ARCHIVE_TOKEN'))
    url = Preference.get_setting('domain')
    url = (url != '' ? 'http://' + url : '')
    if Preference.get_setting('SHOW_AUTHOR_OF_POST') == 'yes'
      author = post.author
      return "#{prefix}<a href=\"#{url}/#{archive_token}/authors/#{author.id.to_s}\" title=\"View all posts by #{author.name}\">#{author.name}</a>"
    end
  end

  def syntax_link( filter = get_pref('TEXT_FILTER'))
    filters = {
      'markdown' => { :id => 'markdown', :url => 'http://daringfireball.net/projects/markdown/syntax' },
      'textile'  => { :id => 'textile',  :url => 'http://www.textism.com/tools/textile/' },
      'convert line breaks' => { :id => 'clb' },
      'plain text' => { :id => 'plaintext' }
    }
    return content_tag( :span,
      %Q{<b>#{filter.titleize}</b> enabled. } + ( filters[filter][:url] ? %Q{See the #{link_to('syntax rules', filters[filter][:url], :title => 'Syntax rules', :target => '_blank')} for help.} : "" ),
        :id => "#{filters[filter][:id]}_syntax_link",
        :class => 'small gray'
      )
  end

end
