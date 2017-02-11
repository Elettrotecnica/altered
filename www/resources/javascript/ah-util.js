// AdHoc Javascript Utilities

//#######################################################################################################################
//                                            Funzionalità generali
//#######################################################################################################################

//=======================================================================================================================
//                                Posizionare un elemento in un punto arbitrario della pagina
//=======================================================================================================================

function ahPlaceElement(eid, x, y) {
    try {
	var element = document.getElementById(eid);
	
	element.style.position = 'absolute';
	element.style.zIndex   = '' + (element.style.zIndex + 1) + '';
	element.style.top      = y + 'px';
	element.style.left     = x + 'px';
    } catch (err) {
	//Molto probabilmente l'elemento fornito non esiste... fallisco silenziosamente.
    }
}

//=======================================================================================================================


//=======================================================================================================================
//                                               Fade di un elemento
//=======================================================================================================================

const TimeToFade  = 1000.0;

function ahFade (eid, timeToFade) {
    if (timeToFade == null) {
	timeToFade = 1000.0;
    }
    
    //Definita estendendo l'oggetto window, la funzione ha visibilità globale.
    //Faccio così invece di definirla esternamente perchè questa funzione ha significato
    //solo contestualmente alla chiamata di ahFade.
    window.ahAnimateFade = function (lastTick, eid) {
	var curTick = new Date().getTime();
	var elapsedTicks = curTick - lastTick;
	var element = document.getElementById(eid);

	if(element.FadeTimeLeft <= elapsedTicks) {
	    element.style.opacity = element.FadeState == 1 ? '1' : '0';
	    element.style.filter = 'alpha(opacity = ' + (element.FadeState == 1 ? '100' : '0') + ')';
	    element.FadeState = element.FadeState == 1 ? 2 : -2;
	    return;
	}

	element.FadeTimeLeft -= elapsedTicks;
	var newOpVal = element.FadeTimeLeft/timeToFade;
	if(element.FadeState == 1) {
	    newOpVal = 1 - newOpVal;
	}

	element.style.opacity = newOpVal;
	element.style.filter = 'alpha(opacity = ' + (newOpVal*100) + ')';
	
	setTimeout("ahAnimateFade(" + curTick + ",'" + eid + "')", 33);
    }

    var element = document.getElementById(eid);
    if(element == null) {
	return;
    }
    
    if (element.FadeState == null) {
	if(element.style.opacity == null || element.style.opacity == '' || element.style.opacity == '1') {
	    element.FadeState = 2;
	}
	else {
	    element.FadeState = -2;
	}
    }
      
    if (element.FadeState == 1 || element.FadeState == -1) {
	element.FadeState = element.FadeState == 1 ? -1 : 1;
	element.FadeTimeLeft = timeToFade - element.FadeTimeLeft;
    }
    else {
	element.FadeState = element.FadeState == 2 ? -1 : 1;
	element.FadeTimeLeft = timeToFade;
	setTimeout("ahAnimateFade(" + new Date().getTime() + ",'" + eid + "')", 33);
    }
}

//=======================================================================================================================


//=======================================================================================================================
//                                   Apre un popup all'url specificato
//=======================================================================================================================

function ahOpenZoom (url, size) {
    var width;
    var height;
    if (size == null) {
	size = medium;
    }
    switch (size)
    {
	case "small":
	  width = 640;
	  height = 240;
	  break;
	case "medium":
	  width = 800;
	  height = 480;
	  break;
	case "large":
	  width = 1024;
	  height = 600;
	  break;
	default:
	  width = 800;
	  height = 480;
	  break;
    }
    
    window.open(url, 'ah_zoom', 'scrollbars=yes,resizable=yes,width=' + width + ',height=' + height);
}

//=======================================================================================================================


//=======================================================================================================================
//                    Autocompleta un campo di form utilizzando un webservice. Utilizza jQuery
//=======================================================================================================================

// fields è un array di array. Ciascun array è nella forma ('id_campo_da_modificare', '/percorso/del/ws')

function ahAutocomplete (fields) {

    // ## AcField ##
    // Questo oggetto 'aggancia' al campo indicato dall'id 'fieldId'
    // la capacita' di autocompletamento usando il webservice 'wsUrl'
    function AcField (fieldId, wsUrl) {
	
	// Funzione di autocompletamento
	this.autocomplete = function () {
	    
	    // Recupero la stringa di ricerca...
	    var searchString = filter.val();
	    
	    // ...se e' nulla annullo il valore del campo...
	    if (searchString.length == 0) {
		field.val('');
	    }
	    
	    // ...e se e' troppo breve non chiamo il webservice.
	    if (searchString.length < minLength - 1) {
		return;
	    }
	  
	    // Posto il valore del campo di ricerca nel webservice...
	    $.get(wsUrl, { query: searchString }, function( xmlResponse ) {
		// ...leggo la risposta: ogni record e' un tag 'data'...
		var data = $( "data", xmlResponse ).map(function() {
		  // ...il cui nome e' il campo name e l'id il campo id.
		  return {
		      value: $( "name", this ).text(),
		      id: $( "id", this ).text()
		  };
		  }).get();
	    	
		filter.autocomplete("option", "source", data);
		//filter.autocomplete("search");
	  });
	}
	
	var minLength = 4;
	
	// Salvo l'url del webservice in una variabile locale
	var wsUrl = wsUrl;
	
	// Recupero il campo da trasformare
	var field = $('#' + fieldId);
	
	// Creo un campo filtro nel quale si scrivera' la stringa di ricerca...
	var filter = $('<input>');
	// facendolo grande come il campo da trasformare.
	filter.attr('size', field.attr('size'));
	
	// Lo colloco appena prima del campo da trasformare...
	field.before(filter);
	// ...che nascondo.
	field.hide();
	
	// Se il campo da trasformare contiene già un valore...
	var val = field.val();
	if (val != '') {
	    // ...interrogo il webservice per recuperare il nome corrispondente.
	    $.get(wsUrl, { id: val }, function( xmlResponse ) {
		filter.val($(xmlResponse).find('name').eq(0).text());
		field.attr('value', $(xmlResponse).find('id').eq(0).text());
	    });
	}
	
	filter.autocomplete({
	    source: [],
	    minLength: minLength,
	    focus: function(event, ui) {
	      field.attr('value',ui.item.id);
	    },
	    change: function(event, ui) {
	      field.change();
	    }
	});
	
	// La ricerca avverra' ad ogni pressione della tastiera.
	filter.keyup(this.autocomplete);
    }

    // Verrà generato un AcField per ogni campo specificato.
    for (var i = 0; i < fields.length; i++) {
	var comboField = fields[i];
	
	var fieldId = comboField[0];
	var wsUrl   = comboField[1];
	
	new AcField(fieldId, wsUrl);
    }
}


//#######################################################################################################################
//                                            Funzionalità OpenACS
//#######################################################################################################################

//=======================================================================================================================
//                             Evidenzia il primo campo di una form OpenACS che presenta un errore
//=======================================================================================================================

function ahFocusError () {
    try {
	var errorLabel = document.getElementsByClassName('form-error')[0];
    
	var errorField = errorLabel.parentNode.getElementsByTagName('input')[0];
    
	//Se non riesco a ottenere il campo della form corrispondente all'errore
	//userò direttamente l'etichetta dell'errore come riferimento
	if (errorField == undefined) {
	    var errorField = errorLabel;
	    //Se uso l'etichetta dovrò scorrere più in basso la pagina
	    var y = errorField.offsetTop + (errorField.offsetHeight * 3) - window.innerHeight;
	} else {
	    var y = errorField.offsetTop + (errorField.offsetHeight * 2) - window.innerHeight;
	}
	
	errorField.focus();
	window.scrollTo(0,y);
    } catch (err) {
	//Molto probabilmente non esiste un tag di errore... fallisco silenziosamente.
    }
}

//=======================================================================================================================


//=======================================================================================================================
//               Fare si che il messaggio informativo in OpenACS sia sempre mostrato in cima allo schermo
//=======================================================================================================================

function ahPlaceAlertOnTop () {
    try {      
	//Recupero l'elemento che contiene i messaggi di allerta
	var alertElement = document.getElementById('alert-message');
	  
	if (alertElement.offsetTop <= window.pageYOffset) {
	    ahPlaceElement('alert-message', 0, window.pageYOffset);
	    setTimeout("ahFade('alert-message',2000)", 3000);
	    alertElement.style.width = '100%';
	}
    } catch (err) {
	//Molto probabilmente non esiste un messaggio d'allerta... fallisco silenziosamente.
    }
}

//=======================================================================================================================


//=======================================================================================================================
//                             Aggiungere funzionalità javascript per OpenAcs ad una form
//=======================================================================================================================

function ahEnhanceForms () {
    var forms = document.forms;
    
    for (var i = 0; i < forms.length; i++) {
	var form = forms[i];
    
	//Aggiunge a tutte le form un metodo 'refresh'
	form.refresh = function () {
	    this.__refreshing_p.value='1';
	    this.submit();
	}
    }
}

//=======================================================================================================================


//=======================================================================================================================
//                             Applica tutte le migliorie per OpenACS alla pagina
//=======================================================================================================================

function ahEnhancePage () {
    ahFocusError();
    ahPlaceAlertOnTop();
    ahEnhanceForms();
}

//=======================================================================================================================
